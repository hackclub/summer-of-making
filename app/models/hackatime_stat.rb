# frozen_string_literal: true

# == Schema Information
#
# Table name: hackatime_stats
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  last_updated_at :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_hackatime_stats_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HackatimeStat < ApplicationRecord
  belongs_to :user

  def total_seconds_for_project(project)
    return 0 if data.blank? || data.dig("data").blank? || !data.dig("data", "projects").is_a?(Array)
    project_keys = project.hackatime_keys
    return 0 if project_keys.blank?

    data.dig("data", "projects").sum do |hackatime_project|
      if project_keys.include?(hackatime_project["name"])
        hackatime_project["total_seconds"]
      else
        0
      end
    end
  end

  def projects
    projects = data&.dig("data", "projects") || []

    projects
      .map { |project| {
        key: project["name"], # Deprecated
        name: project["name"],
        total_seconds: project["total_seconds"],
        formatted_time: project["text"]
      }}
      .reject { |p| [ "<<LAST_PROJECT>>", "Other" ].include?(p[:name]) }
      .sort_by { |p| p[:name] }
  end

  def total_seconds_across_all_projects
    projects.sum { |p| p[:total_seconds] }
  end

  def today_seconds_across_all_projects
    return 0 if data.blank?
    response = Faraday.get("https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?features=projects&start_date=#{Date.current.strftime("%Y-%m-%d")}")
    result = JSON.parse(response.body)
    return unless result["data"]["status"] == "ok"
    total_seconds = result["data"]["total_seconds"] || 0
    total_seconds
  end

  def seconds_since_last_update
    return 0 unless last_updated_at

    (Time.current - last_updated_at).to_i
  end

  def can_post_for_project?(project, required_seconds)
    total_seconds = total_seconds_for_project(project)
    total_seconds >= required_seconds
  end

  def time_since_last_update_for_project(project)
    current_total = total_seconds_for_project(project)

    previous_hackatime_total = project.devlogs.where.not(last_hackatime_time: nil).sum(:last_hackatime_time)

    current_total - previous_hackatime_total
  end

  # 5 minutes
  def can_post_for_project_since_last_update?(project, required_seconds = 300)
    return false unless user.has_hackatime? && project.hackatime_keys.present?

    time_since_last = time_since_last_update_for_project(project)
    time_since_last >= required_seconds
  end

  def seconds_needed_since_last_update(project, required_seconds = 300)
    return required_seconds unless user.has_hackatime?

    time_since_last = time_since_last_update_for_project(project)
    [ required_seconds - time_since_last, 0 ].max
  end

  def has_enough_time_since_last_update?(project, required_seconds = 300)
    return false unless user.has_hackatime? && project.hackatime_keys.present?

    can_post_for_project_since_last_update?(project, required_seconds)
  end
end
