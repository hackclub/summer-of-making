# frozen_string_literal: true

# == Schema Information
#
# Table name: user_hackatime_data
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
#  index_user_hackatime_data_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserHackatimeData < ApplicationRecord
  belongs_to :user

  def total_seconds_for_project(project)
    return 0 if data.blank? || data.dig("data").blank? || !data.dig("data", "projects").is_a?(Array)
    project_keys = project.hackatime_keys
    return 0 if project_keys.blank?

    if project_keys.length == 1
      data.dig("data", "projects").sum do |hackatime_project|
        if project_keys.include?(hackatime_project["name"])
          hackatime_project["total_seconds"]
        else
          0
        end
      end
    else
      Rails.cache.fetch("project_coding_time_#{project.id}_#{project_keys.sort.join(',')}", expires_in: 30.seconds) do
        fetch_combined_project_time(project_keys)
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

  private

  def fetch_combined_project_time(project_keys)
    return 0 unless user.slack_id.present?
    project_keys_string = project_keys.join(",")
    encoded_project_keys = URI.encode_www_form_component(project_keys_string)

    # use utc
    start_time = begin
      Time.use_zone("America/New_York") do
        Time.parse("2025-06-16").beginning_of_day
      end
    end.utc

    direct_url = "https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?filter_by_project=#{encoded_project_keys}&start_date=#{start_time.iso8601}&features=projects"

    begin
      direct_res = Faraday.get(direct_url, nil, { "RACK_ATTACK_BYPASS" => Rails.application.credentials.hackatime&.ratelimit_bypass_header }.compact)

      if direct_res.success?
        direct_data = JSON.parse(direct_res.body)
        direct_data.dig("data", "unique_total_seconds") || direct_data.dig("data", "total_seconds") || 0
      else
        Rails.logger.warn "Failed to fetch combined Hackatime data for user #{user.slack_id}: HTTP #{direct_res.status}"
        0
      end
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error fetching combined Hackatime data for user #{user.slack_id}: #{e.message}"
      0
    rescue => e
      Rails.logger.error "Error fetching combined Hackatime data for user #{user.slack_id}: #{e.message}"
      0
    end
  end
end
