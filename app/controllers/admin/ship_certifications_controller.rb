module Admin
  class ShipCertificationsController < ApplicationController
    before_action :authenticate_ship_certifier!, except: []
    skip_before_action :authenticate_admin!

    def index
      @filter = params[:filter] || "pending"
      @category_filter = params[:category_filter]
      @sort_by = params[:sort_by] || "votes_and_age"

      @category_filter = nil unless @category_filter.present? && Project.certification_types.keys.include?(@category_filter)

      base = ShipCertification
        .left_joins(project: :devlogs)
        .where(projects: { is_deleted: false })
        .group("ship_certifications.id", "projects.id")
        .select("ship_certifications.*, projects.id as project_id, projects.title, projects.category, projects.certification_type, COALESCE(SUM(devlogs.duration_seconds), 0) as devlogs_seconds_total")
        .includes(:project)

      @vote_counts = User.joins(:votes).where(votes: { status: "active" }).group(:id).count

      if params.key?(:category_filter)
        if @category_filter.present?
          base = base.where(projects: { certification_type: @category_filter })
        else
          base = base.where(projects: { certification_type: [ nil, "" ] })
        end
      end

      case @filter
      when "approved"
        @ship_certifications = base.approved
      when "rejected"
        @ship_certifications = base.rejected
      when "returned"
        @ship_certifications = base.where.not(ysws_returned_at: nil)
      when "pending"
        @ship_certifications = base.pending
      when "all"
        @ship_certifications = base
      else
        @filter = "pending"
        @ship_certifications = base.pending
      end

      # Advanced sorting options
      @ship_certifications = case @sort_by
      when "oldest_first"
        # Sort by time without certification (oldest first) - prioritizes queue tackling
        @ship_certifications.sort_by { |cert| cert.created_at }
      when "newest_first"
        # Sort by newest submissions first
        @ship_certifications.sort_by { |cert| -cert.created_at.to_i }
      when "most_votes"
        # Sort by user vote count (highest first)
        @ship_certifications.sort_by do |cert|
          vote_count = @vote_counts[cert.project.user_id] || 0
          -vote_count
        end
      else # "votes_and_age" - default
        # Original sorting: votes descending, then age
        @ship_certifications.sort_by do |cert|
          vote_count = @vote_counts[cert.project.user_id] || 0
          [ -vote_count, cert.created_at ]
        end
      end

      base = ShipCertification.joins(:project).where(projects: { is_deleted: false })
      if @category_filter.present?
        base = base.where(projects: { certification_type: @category_filter })
      end

      @total_approved = base.approved.count
      @total_rejected = base.rejected.count
      @total_pending = base.pending.count
      @total_returned = base.where.not(ysws_returned_at: nil).count
      @avg_turnaround = calc_avg_turnaround

      category_base = ShipCertification.joins(:project).where(projects: { is_deleted: false })
      case @filter
      when "approved"
        category_base = category_base.approved
      when "rejected"
        category_base = category_base.rejected
      when "pending"
        category_base = category_base.pending
      end
      @category_counts = category_base
        .where.not(projects: { certification_type: [ nil, "" ] })
        .group("projects.certification_type")
        .count

      no_type_base = ShipCertification.joins(:project).where(projects: { is_deleted: false })
      case @filter
      when "approved"
        no_type_base = no_type_base.approved
      when "rejected"
        no_type_base = no_type_base.rejected
      when "pending"
        no_type_base = no_type_base.pending
      end
      @no_type_count = no_type_base.where(projects: { certification_type: [ nil ] }).count

      # Calculate this week's Sunday in EST
      est_zone = ActiveSupport::TimeZone.new("America/New_York")
      current_est = Time.current.in_time_zone(est_zone)
      week_start = current_est.beginning_of_week(:sunday)
      @leaderboard_week = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
        .where.not(ship_certifications: { reviewer_id: nil })
        .where("ship_certifications.updated_at >= ?", week_start)
        .group("users.id", "users.display_name", "users.email")
        .order("COUNT(ship_certifications.id) DESC")
        .limit(20)
        .pluck("users.display_name", "users.email", "COUNT(ship_certifications.id)")

      @leaderboard_day = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
        .where.not(ship_certifications: { reviewer_id: nil })
        .where("ship_certifications.updated_at >= ?", 24.hours.ago)
        .group("users.id", "users.display_name", "users.email")
        .order("COUNT(ship_certifications.id) DESC")
        .limit(20)
        .pluck("users.display_name", "users.email", "COUNT(ship_certifications.id)")

      @leaderboard_all = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
        .where.not(ship_certifications: { reviewer_id: nil })
        .group("users.id", "users.display_name", "users.email")
        .order("COUNT(ship_certifications.id) DESC")
        .limit(20)
        .pluck("users.display_name", "users.email", "COUNT(ship_certifications.id)")

      @decided_last_24h = ShipCertification.where.not(judgement: :pending)
        .where("ship_certifications.updated_at >= ?", 24.hours.ago)
        .where("ship_certifications.updated_at > ship_certifications.created_at")
        .joins(:project).where(projects: { is_deleted: false })
        .count

      @submitted_last_24h = ShipCertification
        .where("ship_certifications.created_at >= ?", 24.hours.ago)
        .joins(:project).where(projects: { is_deleted: false })
        .count

      # Load ysws_returned_by users for the filtered certifications to avoid N+1 queries
      returned_by_ids = @ship_certifications.map(&:ysws_returned_by_id).compact.uniq
      @returned_by_users = User.where(id: returned_by_ids).index_by(&:id) if returned_by_ids.any?

      # Get weekly leaderboard positions for tiered payment rates
      weekly_positions = {}
      @leaderboard_week.each_with_index do |(name, email, count), index|
        user_key = name || email
        weekly_positions[user_key] = index + 1
      end

      # Calculate payment stats for reviewers including pending requests
      @payment_stats = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
        .joins("LEFT JOIN payouts ON users.id = payouts.user_id AND payouts.reason LIKE 'Ship certification review payment:%'")
        .joins("LEFT JOIN ship_reviewer_payout_requests ON users.id = ship_reviewer_payout_requests.reviewer_id")
        .where.not(ship_certifications: { reviewer_id: nil })
        .group("users.id", "users.display_name", "users.email")
        .select("users.display_name", "users.email", "COUNT(DISTINCT ship_certifications.id) as review_count", "COALESCE(SUM(payouts.amount), 0) as total_paid", "COALESCE(SUM(CASE WHEN ship_reviewer_payout_requests.status = 0 THEN ship_reviewer_payout_requests.amount ELSE 0 END), 0) as pending_amount")
        .order("total_paid DESC")
        .limit(20)
        .map do |stat|
          name = stat.display_name
          email = stat.email
          user_key = name || email

          # Determine payment rate based on weekly leaderboard position
          position = weekly_positions[user_key]
          shells_per_review = case position
          when 1..3
            1.5  # 1st to 3rd place
          when 4..7
            1.0  # 4th to 7th place
          else
            0.75 # 8th place onward
          end

          total_earned = stat.review_count.to_i * shells_per_review
          total_paid = stat.total_paid.to_f
          total_owed = [ total_earned - total_paid, 0 ].max
          pending_amount = stat.pending_amount.to_f
          review_count = stat.review_count.to_i

          [ name, email, total_owed, shells_per_review, pending_amount ]
        end
    end

    def edit
      @ship_certification = ShipCertification.includes(project: [ :user, :ship_events ]).find(params[:id])
      @ship_certification.reviewer = current_user if @ship_certification.reviewer.nil?
    end

    def update
      @ship_certification = ShipCertification.find(params[:id])

      # Validate form requirements
      validation_errors = validate_certification_requirements

      if validation_errors.any?
        @ship_certification.errors.add(:base, "Please complete all requirements:")
        validation_errors.each { |error| @ship_certification.errors.add(:base, "• #{error}") }
        render :edit, status: :unprocessable_entity
        return
      end

      if @ship_certification.update(ship_certification_params)
        # Create improvement suggestion if provided
        if params[:improvement_suggestion].present?
          ShipwrightAdvice.create!(
            project: @ship_certification.project,
            ship_certification: @ship_certification,
            description: params[:improvement_suggestion].strip
          )
        end

        redirect_to admin_ship_certifications_path, notice: "Ship certification updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def logs
      @logs = ShipCertification
        .includes(:project, :reviewer)
        .where(projects: { is_deleted: false })
        .where.not(judgement: :pending)
        .order(updated_at: :desc)
        .limit(500) # this should be the limit of how much shit we need

      @total_approved = ShipCertification.approved.count
      @total_rejected = ShipCertification.rejected.count
      @total_processed = @total_approved + @total_rejected

      # Average decision time
      @avg_turnaround = calc_avg_turnaround

      # Leaderboard - reviewers by number of certifications reviewed
      @leaderboard = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
                         .where.not(ship_certifications: { reviewer_id: nil })
                         .group("users.id", "users.display_name", "users.email")
                         .order("COUNT(ship_certifications.id) DESC")
                         .limit(10)
                         .pluck("users.display_name", "users.email", "COUNT(ship_certifications.id)")
    end

    private

    def validate_certification_requirements
      errors = []

      # Check if all required checkboxes are checked
      unless params[:checked_demo] == "1" || params[:checked_demo] == "on"
        errors << 'Check "I looked at the demo"'
      end

      unless params[:checked_repo] == "1" || params[:checked_repo] == "on"
        errors << 'Check "I looked at the repo"'
      end

      unless params[:checked_description] == "1" || params[:checked_description] == "on"
        errors << 'Check "I looked at the description"'
      end

      # Check if status is not pending
      if params[:ship_certification][:judgement] == "pending"
        errors << 'Change status from "pending" to approved or rejected'
      end

      # Check if proof video is uploaded (either new upload or existing)
      has_new_video = params[:ship_certification][:proof_video].present?
      has_existing_video = @ship_certification.proof_video.attached?

      unless has_new_video || has_existing_video
        errors << "Upload a proof video"
      end

      errors
    end

    def calc_avg_turnaround
      pending_certs = ShipCertification
        .where(judgement: :pending)
        .joins(:project)
        .where(projects: { is_deleted: false })

      return nil if pending_certs.empty?

      current_time = Time.current
      total_time = pending_certs.sum { |cert| current_time - cert.created_at }
      avg_sec = total_time / pending_certs.count

      {
        s: avg_sec,
        h: (avg_sec / 3600).to_i,
        m: ((avg_sec % 3600) / 60).to_i,
        d: (avg_sec / 86400).to_i
      }
    end

    def authenticate_ship_certifier!
      redirect_to root_path unless current_user&.admin_or_ship_certifier?
    end

    def ship_certification_params
      params.require(:ship_certification).permit(:judgement, :notes, :reviewer_id, :proof_video)
    end
  end
end
