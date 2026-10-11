# frozen_string_literal: true

class TrackViewJob < ApplicationJob
  queue_as :literally_whenever

  def perform(viewable_type:, viewable_id:, user_id: nil, ip_address: nil, user_agent: nil)
    viewable = viewable_type.constantize.find_by(id: viewable_id)
    return unless viewable

    # first check, because caching is a bitch
    return unless ViewTrackingService.should_count_view?(viewable, user_id: user_id, ip_address: ip_address)

    # dedupe shit
    ViewTrackingService.mark_as_viewed(viewable, user_id: user_id, ip_address: ip_address)

    ViewTrackingService.increment_view_count(viewable)

    ViewTrackingService.create_view_event(viewable, user_id: user_id, ip_address: ip_address, user_agent: user_agent)
  rescue ActiveRecord::RecordNotFound
  rescue StandardError => e
  end
end
