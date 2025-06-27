# frozen_string_literal: true

class RefreshHackatimeStatsJob < ApplicationJob
  queue_as :literally_whenever

  def perform(user_id, options = {})
    user = User.find_by(id: user_id)
    return unless user&.has_hackatime

    response = user.fetch_raw_hackatime_stats
    return unless response.success?

    result = JSON.parse(response.body)

    stats = user.hackatime_stat || user.build_hackatime_stat
    stats.update(data: result, last_updated_at: Time.current)
  end
end
