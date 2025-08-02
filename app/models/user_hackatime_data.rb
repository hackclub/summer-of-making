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
        result = fetch_combined_project_time_with_date(project_keys, "2025-06-16")
        if result.nil?
          Rails.logger.warn "Failed to fetch Hackatime data for project #{project.id} with keys #{project_keys} - using 0"
          Honeybadger.notify("UserHackatimeData API failure", context: {
            user_id: user.id,
            slack_id: user.slack_id,
            project_id: project.id,
            project_keys: project_keys
          })
          0
        else
          result
        end
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

  def fetch_neighborhood_total_time(project_keys)
    # for neighbourhood projects we do may 1 thingie
    Rails.cache.fetch("neighborhood_total_time_#{user.id}_#{project_keys.sort.join(',')}", expires_in: 10.seconds) do
      result = fetch_combined_project_time_with_date(project_keys, "2025-05-01")
      if result.nil?
        Rails.logger.warn "Failed to fetch neighborhood total Hackatime data for user #{user.slack_id} with keys #{project_keys} - using 0"
        0
      else
        result
      end
    end
  end

  private

  def fetch_combined_project_time_with_date(project_keys, start_date_string)
    return 0 unless user.slack_id.present?
    project_keys_string = project_keys.join(",")
    encoded_project_keys = URI.encode_www_form_component(project_keys_string)

    # use utc
    start_time = begin
      Time.use_zone("America/New_York") do
        Time.parse(start_date_string).beginning_of_day
      end
    end.utc

    direct_url = "https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?filter_by_project=#{encoded_project_keys}&start_date=#{start_time.iso8601}&features=projects&total_seconds=true&test_param=true"

    begin
      headers = { "RACK_ATTACK_BYPASS" => ENV["HACKATIME_BYPASS_KEYS"] }.compact
      direct_res = Faraday.get(direct_url, nil, headers)

      if direct_res.success?
        direct_data = JSON.parse(direct_res.body)
        direct_data.dig("total_seconds")
      else
        Rails.logger.warn "Failed to fetch combined Hackatime data for user #{user.slack_id}: HTTP #{direct_res.status}"
        Honeybadger.notify("UserHackatimeData API failure", context: {
          user_id: user.id,
          slack_id: user.slack_id,
          status: direct_res.status,
          project_keys: project_keys
        })
        nil
      end
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error fetching combined Hackatime data for user #{user.slack_id}: #{e.message}"
      Honeybadger.notify("UserHackatimeData JSON parse error", context: { user_id: user.id, slack_id: user.slack_id, error: e.message })
      nil
    rescue => e
      Rails.logger.error "Error fetching combined Hackatime data for user #{user.slack_id}: #{e.message}"
      Honeybadger.notify("UserHackatimeData error", context: { user_id: user.id, slack_id: user.slack_id, error: e.message })
      nil
    end
  end
end
