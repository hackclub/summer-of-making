class MapController < ApplicationController
  before_action :authenticate_user!
  before_action :check_identity_verification

  def index
    @projects_on_map = Cache::MapPointsJob.perform_now
    @placeable_projects = current_user.projects.joins(:ship_events).not_on_map.distinct.order(created_at: :desc)

    respond_to do |format|
      format.html { @projects_on_map = @projects_on_map.to_json }
      format.json { render json: { projects: @projects_on_map } }
    end
  end

  private

  def check_identity_verification
    return if current_user&.identity_vault_id.present? && current_verification_status != :ineligible

    redirect_to campfire_path, alert: "Please verify your identity to access this page."
  end
end
