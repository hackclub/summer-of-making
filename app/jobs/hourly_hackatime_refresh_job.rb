# frozen_string_literal: true

class HourlyHackatimeRefreshJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    users = User.where(has_hackatime: true).distinct

    from = "2025-05-16"
    to = Time.zone.today.strftime("%Y-%m-%d")

    jobs = users.map { |u| RefreshHackatimeStatsJob.new(u.id, from: from, to: to) }
    ActiveJob.perform_all_later(jobs)

    Rails.logger.debug { "Hourly Hackatime refresh job performed for #{jobs.size} users" }
    message = "Hourly Hackatime refresh job performed for #{jobs.size} users"

    begin
      client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))
      Rails.logger.debug { "Sending Slack message: #{message}" }
      client.chat_postMessage(
        channel: "C08TRKC44UU",
        text: message,
        as_user: true
      )
    rescue Slack::Web::Api::Errors::SlackError => e
      Rails.logger.error("Failed to send Slack message: #{e.message}")
    end
  end
end
