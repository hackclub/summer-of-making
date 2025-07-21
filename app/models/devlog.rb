# frozen_string_literal: true

require "cgi"

# == Schema Information
#
# Table name: devlogs
#
#  id                              :bigint           not null, primary key
#  attachment                      :string
#  comments_count                  :integer          default(0), not null
#  duration_seconds                :integer          default(0), not null
#  hackatime_projects_key_snapshot :jsonb            not null
#  hackatime_pulled_at             :datetime
#  last_hackatime_time             :integer
#  likes_count                     :integer          default(0), not null
#  seconds_coded                   :integer
#  text                            :text
#  views_count                     :integer          default(0), not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  project_id                      :bigint           not null
#  user_id                         :bigint           not null
#
# Indexes
#
#  index_devlogs_on_project_id   (project_id)
#  index_devlogs_on_user_id      (user_id)
#  index_devlogs_on_views_count  (views_count)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class Devlog < ApplicationRecord
  belongs_to :user
  belongs_to :project, counter_cache: { active: false }
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :timer_sessions, dependent: :nullify
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :file

  validates :text, presence: true
  validate :file_must_be_attached, on: %i[ create ]

  # Validates if only MD changes are made
  validate :only_formatting_changes, on: :update

  validate :updates_not_locked, on: :create

  after_commit :notify_followers_and_stakers, on: :create

  def formatted_text
    ApplicationController.helpers.markdown(text)
  end

  def liked_by?(user)
    return false unless user

    likes.exists?(user: user)
  end

  # ie. Project.first.devlogs.capped_duration_seconds
  scope :capped_duration_seconds, -> { where.not(duration_seconds: nil).sum("LEAST(duration_seconds, #{10.hours.to_i})") }

  def recalculate_seconds_coded
    # find the created_at of the devlog directly before this one
    prev_time = Devlog.where(project_id: project_id)
                        .where("created_at < ?", created_at)
                        .order(created_at: :desc)
                        .first&.created_at

    # alternatively, record from the beginning of the event
    prev_time ||= begin
      Time.use_zone("America/New_York") do
        Time.parse("2025-06-16").beginning_of_day
      end
    end.utc

    begin
      if hackatime_projects_key_snapshot.present?
        project_keys = hackatime_projects_key_snapshot.join(",")
        encoded_project_keys = URI.encode_www_form_component(project_keys)
        direct_url = "https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?filter_by_project=#{encoded_project_keys}&start_date=#{prev_time.iso8601}&end_date=#{created_at.utc.iso8601}&features=projects"

        # rake attach bypass
        headers = { "RACK_ATTACK_BYPASS" => Rails.application.credentials.hackatime&.ratelimit_bypass_header }.compact
        direct_res = Faraday.get(direct_url, nil, headers)

        if direct_res.success?
          direct_data = JSON.parse(direct_res.body)
          duration_seconds = direct_data.dig("data", "unique_total_seconds") || direct_data.dig("data", "total_seconds") || 0
        else
          Rails.logger.error "Hackatime API failed for devlog #{id}: HTTP #{direct_res.status} - #{direct_res.body}"
          duration_seconds = 0
        end
      else
        duration_seconds = 0
      end

      duration_seconds = 0 if duration_seconds.nil?

      Rails.logger.info "\tDevlog #{id} duration_seconds: #{duration_seconds}"
      update!(duration_seconds: duration_seconds, hackatime_pulled_at: Time.now)
      true
    rescue => e
      Rails.logger.error "Unexpected error in recalculate_seconds_coded for Devlog #{id}: #{e.message}"
      Honeybadger.notify(
        error_class: "Devlog recalculation error",
        error_message: e.message,
        context: { devlog_id: id, user_id: user_id, project_id: project_id }
      )

      # set safe defaults
      update!(duration_seconds: 0, hackatime_pulled_at: Time.now)
      false
    end
  end

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def updates_not_locked
    return unless ENV["UPDATES_STATUS"] == "locked"

    errors.add(:base, "Posting updates is currently locked")
  end

  def only_formatting_changes
    return unless text_changed? && persisted?

    original_stripped = strip_formatting(text_was)
    new_stripped = strip_formatting(text)

    return unless original_stripped != new_stripped

    errors.add(:text, "You can only modify formatting (markdown, spaces, line breaks), not the content")
  end

  def strip_formatting(text)
    return "" if text.nil?

    text.gsub(/[\s\n\r\t\*\_\#\~\`\>\<\-\+\.\,\;\:\!\?\(\)\[\]\{\}]/i, "").downcase
  end

  def notify_followers_and_stakers
    NotifyProjectDevlogJob.perform_later(id)
  end
end
