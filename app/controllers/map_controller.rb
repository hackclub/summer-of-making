class MapController < ApplicationController
  before_action :authenticate_user!
  before_action :check_identity_verification
  include MapHelper

  def index
    @projects_on_map = project_map_data(map_projects_query).to_json
    @placeable_projects = current_user.projects.joins(:ship_events).not_on_map.distinct.order(created_at: :desc)
  end

  def points
    render json: { projects: project_map_data(map_projects_query) }
  end

  def check_identity_verification
    return if current_user&.identity_vault_id.present? && current_verification_status != :ineligible

    redirect_to campfire_path, alert: "Please verify your identity to access this page."
  end
end
