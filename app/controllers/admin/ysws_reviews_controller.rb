module Admin
  class YswsReviewsController < ApplicationController
  def index
    @filter = params[:filter] || "pending"
    @sort_by = params[:sort_by] || "random"

    base = Project.ysws_review_eligible
      .left_joins(:devlogs)
      .group("projects.id")
      .select("projects.*,
               COUNT(DISTINCT devlogs.id) as devlogs_count,
               COALESCE(SUM(devlogs.duration_seconds), 0) as total_seconds_coded,
               (SELECT elo_after FROM vote_changes WHERE project_id = projects.id ORDER BY created_at DESC LIMIT 1) as elo_score")
      .includes(:user, :devlogs, :project_language, ship_certifications: :reviewer)

    case @filter
    when "pending"
      # Projects with approved ship cert but no YSWS review yet
      reviewed_project_ids = Project.joins(devlogs: :ysws_review_approval).pluck(:id)
      @projects = base.where.not(id: reviewed_project_ids)
    when "reviewed"
      # Projects that have been reviewed
      @projects = base.joins(devlogs: :ysws_review_approval)
    when "all"
      @projects = base
    else
      @filter = "pending"
      reviewed_project_ids = Project.joins(devlogs: :ysws_review_approval).pluck(:id)
      @projects = base.where.not(id: reviewed_project_ids)
    end

    # Apply language filtering
    if params[:lang_filter].present?
      @projects = apply_language_filter(@projects, params[:lang_filter])
    end

    # Apply sorting
    case @sort_by
    when "random"
      @projects = @projects.order(Arel.sql("RANDOM()"))
    when "created_asc"
      @projects = @projects.order(created_at: :asc)
    when "created_desc"
      @projects = @projects.order(created_at: :desc)
    when "elo_asc"
      @projects = @projects.order(Arel.sql("elo_score ASC NULLS LAST"))
    when "elo_desc"
      @projects = @projects.order(Arel.sql("elo_score DESC NULLS LAST"))
    else
      @projects = @projects.order(Arel.sql("elo_score DESC NULLS LAST")).order(created_at: :desc)
    end

    # Eager load latest vote changes to avoid N+1
    project_ids = @projects.to_a.map(&:id)
    @latest_vote_changes = VoteChange
      .where(project_id: project_ids)
      .where("vote_changes.created_at = (
        SELECT MAX(created_at)
        FROM vote_changes vc2
        WHERE vc2.project_id = vote_changes.project_id
      )")
      .index_by(&:project_id)

    # Calculate counts for filter tabs
    eligible_base = Project.ysws_review_eligible
    reviewed_project_ids = Project.joins(devlogs: :ysws_review_approval).pluck(:id)
    @total_pending = eligible_base.where.not(id: reviewed_project_ids).count
    @total_reviewed = eligible_base.where(id: reviewed_project_ids).count
    @total_all = eligible_base.count
  end

  def show
    @project = Project.find(params[:id])
    @ship_events = @project.ship_events.order(:created_at)
    @grouped_devlogs = {}

    @ship_events.each do |ship_event|
      @grouped_devlogs[ship_event] = ship_event.devlogs_since_last.includes(:ysws_review_approval, :file_attachment).order(:created_at)
    end

    # Handle devlogs after the last ship event (if any)
    if @ship_events.any?
      last_ship_date = @ship_events.last.created_at
      devlogs_after_last_ship = @project.devlogs.where("created_at > ?", last_ship_date).includes(:ysws_review_approval, :file_attachment).order(:created_at)
      if devlogs_after_last_ship.any?
        @grouped_devlogs[nil] = devlogs_after_last_ship
      end
    else
      # No ship events, show all devlogs
      @grouped_devlogs[nil] = @project.devlogs.includes(:ysws_review_approval, :file_attachment).order(:created_at)
    end
  end

  def update
    @project = Project.find(params[:id])
    devlog_approvals = params[:devlog_approvals] || {}

    devlog_approvals.each do |devlog_id, approval_params|
      devlog = @project.devlogs.find(devlog_id)

      approval = devlog.ysws_review_approval ||
                devlog.build_ysws_review_approval(user: current_user)

      # Convert minutes to seconds for storage
      approved_seconds = if approval_params[:approved_minutes].present?
        approval_params[:approved_minutes].to_i * 60
      else
        approval_params[:approved_seconds].to_i
      end

      # Determine approval status from checkboxes
      is_approved = approval_params[:approved] == "1"
      is_rejected = approval_params[:rejected] == "1"
      # If both are checked or neither is checked, use approved (default behavior)
      final_approved = is_approved || !is_rejected

      approval.assign_attributes(
        approved: final_approved,
        approved_seconds: approved_seconds,
        notes: approval_params[:notes],
        reviewed_at: Time.current
      )

      approval.save!
    end

    # Create or update the YSWS submission record
    submission = @project.ysws_review_submission || @project.build_ysws_review_submission
    submission.reviewer ||= current_user
    submission.save!

    # Sync to Airtable immediately after approval
    YswsReview::SyncSubmissionJob.perform_later(submission.id)

    redirect_to admin_ysws_reviews_path, notice: "Project review completed successfully"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_ysws_review_path(@project), alert: "Error saving review: #{e.message}"
  end

  def return_to_certifier
    @project = Project.find(params[:id])
    feedback_reasons = params[:feedback_reasons] || []

    ship_certification = @project.latest_ship_certification
    if ship_certification
      ship_certification.update!(
        ysws_feedback_reasons: feedback_reasons.to_json,
        ysws_returned_by: current_user,
        ysws_returned_at: Time.current,
        judgement: :pending  # Reset to pending for re-review
      )

      redirect_to admin_ysws_reviews_path, notice: "Project returned to ship certifier with feedback"
    else
      redirect_to admin_ysws_reviews_path, alert: "No ship certification found for this project"
    end
  end

  private

  def apply_language_filter(projects, filter_string)
    terms = filter_string.split(" ").reject(&:blank?)
    required_languages = []
    excluded_languages = []

    terms.each do |term|
      clean_term = term.strip.downcase
      if clean_term.start_with?("-")
        excluded_languages << clean_term[1..]
      elsif clean_term.start_with?("+")
        required_languages << clean_term[1..]
      else
        required_languages << clean_term
      end
    end

    # Build subquery for projects that match language criteria
    # Only include projects with synced status and non-empty language stats
    language_query = ProjectLanguage.where(status: :synced)
                                    .where.not(language_stats: {})

    # Filter by required languages
    required_languages.each do |lang|
      language_query = language_query.where(
        "EXISTS (SELECT 1 FROM jsonb_object_keys(language_stats) AS key WHERE LOWER(key) = LOWER(?))",
        lang
      )
    end

    # Filter by excluded languages
    excluded_languages.each do |lang|
      language_query = language_query.where(
        "NOT EXISTS (SELECT 1 FROM jsonb_object_keys(language_stats) AS key WHERE LOWER(key) = LOWER(?))",
        lang
      )
    end

    # Apply as a WHERE condition using project IDs
    projects.where(id: language_query.select(:project_id))
  end
  end
end
