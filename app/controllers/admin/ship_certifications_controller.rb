module Admin
  class ShipCertificationsController < ApplicationController
    def index
      @ship_certifications = ShipCertification
        .left_joins(project: :devlogs)
        .where(projects: { is_deleted: false })
        .group("ship_certifications.id", "projects.id")
        .select("ship_certifications.*, projects.id as project_id, projects.title, projects.category, projects.certification_type, COALESCE(SUM(devlogs.last_hackatime_time), 0) as devlogs_seconds_total")
        .includes(:project)
        .order(updated_at: :asc)

      # Totals
      @total_approved = ShipCertification.approved.count
      @total_rejected = ShipCertification.rejected.count
      @total_pending = ShipCertification.pending.count

      # Leaderboard - reviewers by number of certifications reviewed
      @leaderboard = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
                         .where.not(ship_certifications: { reviewer_id: nil })
                         .group("users.id", "users.display_name", "users.email")
                         .order("COUNT(ship_certifications.id) DESC")
                         .limit(10)
                         .pluck("users.display_name", "users.email", "COUNT(ship_certifications.id)")
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

    private

    def ship_certification_params
      params.require(:ship_certification).permit(:judgement, :notes, :reviewer_id, :proof_video)
    end
  end
end
