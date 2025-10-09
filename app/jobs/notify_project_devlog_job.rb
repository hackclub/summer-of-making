# frozen_string_literal: true

class NotifyProjectDevlogJob < ApplicationJob
  queue_as :latency_5m

  def perform(devlog_id)
    devlog = Devlog.find(devlog_id)
    return unless devlog

    project = devlog.project
    return unless project # Skip if project is nil

    devlog.user

    follower_slack_ids = project.project_follows.joins(:user).pluck("users.slack_id").compact
    stonk_slack_ids = project.stonks.joins(:user).pluck("users.slack_id").compact

    both_slack_ids = follower_slack_ids & stonk_slack_ids

    only_follower_slack_ids = follower_slack_ids - stonk_slack_ids
    only_stonk_slack_ids = stonk_slack_ids - follower_slack_ids

    jobs = []

    both_slack_ids.each do |slack_id|
      message = "New devlog on a project you follow AND have stonked! :heart: :stonksss: Check it out at #{project_url(project)}! Show some love and engage with the author!"
      jobs << SendSlackDmJob.new(slack_id, message)
    end

    only_follower_slack_ids.each do |slack_id|
      message = "New devlog on a project you follow! :heart: Check it out at #{project_url(project)}! Show some love and engage with the author!"
      jobs << SendSlackDmJob.new(slack_id, message)
    end

    only_stonk_slack_ids.each do |slack_id|
      message = "New devlog on a project you have stonked! :stonksss: Check it out at #{project_url(project)}! Show some love and engage with the author!"
      jobs << SendSlackDmJob.new(slack_id, message)
    end

    ActiveJob.perform_all_later(jobs)
  end

  private

  def project_url(project)
    Rails.application.routes.url_helpers.project_url(project, host: ENV.fetch("APP_HOST", nil))
  end
end
