module Admin
  class ShipCertificationsController < ApplicationController
    before_action :authenticate_ship_certifier!, except: []
    skip_before_action :authenticate_admin!

    def index
      @filter = params[:filter] || "pending"
      @category_filter = params[:category_filter]

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
      when "pending"
        @ship_certifications = base.pending
      when "all"
        @ship_certifications = base
      else
        @filter = "pending"
        @ship_certifications = base.pending
      end

      @ship_certifications = @ship_certifications.sort_by do |cert|
        vote_count = @vote_counts[cert.project.user_id] || 0
        [ -vote_count, cert.created_at ]
      end

      base = ShipCertification.joins(:project).where(projects: { is_deleted: false })
      if @category_filter.present?
        base = base.where(projects: { certification_type: @category_filter })
      end

      @total_approved = base.approved.count
      @total_rejected = base.rejected.count
      @total_pending = base.pending.count
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

      @leaderboard_week = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
        .where.not(ship_certifications: { reviewer_id: nil })
        .where("ship_certifications.updated_at >= ?", 7.days.ago)
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
    end

    def edit
      @ship_certification = ShipCertification.includes(project: [ :user, :ship_events ]).find(params[:id])
      @ship_certification.reviewer = current_user if @ship_certification.reviewer.nil?
    end

    def update
      @ship_certification = ShipCertification.find(params[:id])

      if @ship_certification.update(ship_certification_params)
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

    def calc_avg_turnaround
      pc = ShipCertification
        .where.not(judgement: :pending)
        .where("ship_certifications.updated_at > ship_certifications.created_at")

      return nil if pc.empty?

      total_time = pc.sum { |cert| cert.updated_at - cert.created_at }
      avg_sec = total_time / pc.count

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
