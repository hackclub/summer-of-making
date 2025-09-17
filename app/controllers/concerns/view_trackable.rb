# frozen_string_literal: true

module ViewTrackable
  extend ActiveSupport::Concern

  private

  def track_view(viewable)
    return unless viewable
    return if request.user_agent.starts_with?("node")

    ViewTrackingService.track_view(
      viewable,
      user_id: current_user&.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
