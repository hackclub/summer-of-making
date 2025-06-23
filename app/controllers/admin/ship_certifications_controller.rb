module Admin
  class ShipCertificationsController < ApplicationController
    def index
      @ship_certifications = ShipCertification.includes(:project).order(updated_at: :asc)
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
        render :edit
      end
    end

    private

    def ship_certification_params
      params.require(:ship_certification).permit(:judgement, :notes, :reviewer_id, :proof_video)
    end
  end
end
