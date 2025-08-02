# frozen_string_literal: true

# This refreshes every user's Hackatime Project data.
class UserHackatimeDataRefreshJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  def perform
    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Starting")
    end

    User.where(has_hackatime: true).find_each do |user|
      # For batch processing: refresh data without caching (includes warning checks)
      user.refresh_hackatime_data_now!
    end

    Rails.logger.tagged("UserHackatimeDataRefreshJob") do
      Rails.logger.info("Ended")
    end
  end
end
