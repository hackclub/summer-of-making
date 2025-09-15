# frozen_string_literal: true

class ViewTrackingController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]
  before_action :authenticate_request

  ALLOWED_VIEWABLES = {
    "Project" => Project,
    "Devlog" => Devlog
  }.freeze

  def create
    # TEMP
    return render json: { success: true }

    viewable_type = params[:viewable_type]
    viewable_id = params[:viewable_id]

    klass = ALLOWED_VIEWABLES[viewable_type]
    unless klass && viewable_id.present?
      render json: { error: "wuh" }, status: :bad_request
      return
    end

    viewable = klass.find_by(id: viewable_id)
    unless viewable
      render json: { error: "#{viewable_type} not found" }, status: :not_found
      return
    end

    ViewTrackingService.track_view(
      viewable,
      user_id: current_user&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    render json: { success: true }
  end

  private

  def authenticate_request
    true
  end
end
