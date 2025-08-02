module Admin
  class YswsReviewsController < ApplicationController
  def index
    @filter = params[:filter] || "pending"

    base = Project.ysws_review_eligible
      .left_joins(:devlogs)
      .group("projects.id")
      .select("projects.*,
               COUNT(DISTINCT devlogs.id) as devlogs_count,
               (SELECT elo_after FROM vote_changes WHERE project_id = projects.id ORDER BY created_at DESC LIMIT 1) as elo_score")
      .includes(:user, :devlogs)

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

    @projects = @projects.order(Arel.sql("elo_score DESC NULLS LAST")).order(created_at: :desc)

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
      @grouped_devlogs[ship_event] = ship_event.devlogs_since_last.includes(:ysws_review_approval).order(:created_at)
    end

    # Handle devlogs after the last ship event (if any)
    if @ship_events.any?
      last_ship_date = @ship_events.last.created_at
      devlogs_after_last_ship = @project.devlogs.where("created_at > ?", last_ship_date).includes(:ysws_review_approval).order(:created_at)
      if devlogs_after_last_ship.any?
        @grouped_devlogs[nil] = devlogs_after_last_ship
      end
    else
      # No ship events, show all devlogs
      @grouped_devlogs[nil] = @project.devlogs.includes(:ysws_review_approval).order(:created_at)
    end
  end

  def update
    @project = Project.find(params[:id])
    devlog_approvals = params[:devlog_approvals] || {}

    devlog_approvals.each do |devlog_id, approval_params|
      devlog = @project.devlogs.find(devlog_id)

      approval = devlog.ysws_review_approval ||
                devlog.build_ysws_review_approval(user: current_user)

      approval.assign_attributes(
        approved: approval_params[:approved] == "1",
        approved_seconds: approval_params[:approved_seconds].to_i,
        notes: approval_params[:notes],
        reviewed_at: Time.current
      )

      approval.save!
    end

    # Create or update the YSWS submission record
    submission = @project.ysws_review_submission || @project.build_ysws_review_submission
    submission.save!

    # Sync to Airtable immediately after approval
    YswsReview::SyncSubmissionJob.perform_now(submission.id)

    redirect_to admin_ysws_reviews_path, notice: "Project review completed successfully"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_ysws_review_path(@project), alert: "Error saving review: #{e.message}"
  end
  end
end
