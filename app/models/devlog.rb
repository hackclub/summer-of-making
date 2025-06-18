# frozen_string_literal: true

# == Schema Information
#
# Table name: devlogs
#
#  id                  :bigint           not null, primary key
#  attachment          :string
#  comments_count      :integer          default(0), not null
#  last_hackatime_time :integer
#  likes_count         :integer          default(0), not null
#  text                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  project_id          :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_devlogs_on_project_id  (project_id)
#  index_devlogs_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class Devlog < ApplicationRecord
  belongs_to :user
  belongs_to :project, counter_cache: true
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :timer_sessions, dependent: :nullify
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :file

  attr_accessor :timer_session_id

  validates :text, presence: true
  validate :file_must_be_attached

  # Validates if only MD changes are made
  validate :only_formatting_changes, on: :update

  validate :updates_not_locked, on: :create
  validate :validate_timer_session_not_linked, on: :create
  validate :validate_timer_session_required, on: :create
  validate :validate_hackatime_time_since_last_update, on: :create

  after_destroy :delete_from_airtable
  after_commit :sync_to_airtable, on: %i[create update]
  after_commit :associate_timer_session, on: :create
  after_commit :notify_followers_and_stakers, on: :create

  def formatted_text
    ApplicationController.helpers.markdown(text)
  end

  def liked_by?(user)
    return false unless user

    likes.exists?(user: user)
  end

  delegate :count, to: :likes, prefix: true

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def validate_timer_session_required
    has_hackatime = project.hackatime_project_keys.present? &&
                    project.user.has_hackatime? &&
                    project.user.hackatime_stat&.has_enough_time_since_last_update?(project)

    return unless timer_session_id.blank? && !has_hackatime

    errors.add(:timer_session_id, "You need to track time with Timer Session or Hackatime")
  end

  def validate_timer_session_not_linked
    return if timer_session_id.blank?

    timer_session = TimerSession.find_by(id: timer_session_id)
    return unless timer_session && timer_session.devlog_id.present?

    errors.add(:timer_session_id, "This timer session is already linked to another update")
  end

  def validate_hackatime_time_since_last_update
    return unless project.hackatime_project_keys.present? && project.user.has_hackatime?
    return if timer_session_id.present?

    return if project.user.hackatime_stat&.has_enough_time_since_last_update?(project)

    seconds_needed = project.user.hackatime_stat&.seconds_needed_since_last_update(project) || 300
    errors.add(:base,
               "You need to spend more time on this project before posting an update. #{ActionController::Base.helpers.format_seconds(seconds_needed)} more needed since your last update.")
  end

  def associate_timer_session
    return if timer_session_id.blank?

    timer_session = project.timer_sessions.find_by(id: timer_session_id)
    return unless timer_session
    return if timer_session.devlog_id.present?

    timer_session.update(devlog: self)
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

  def sync_to_airtable
    SyncUpdateToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteUpdateFromAirtableJob.perform_later(id)
  end

  def notify_followers_and_stakers
    NotifyProjectDevlogJob.perform_later(id)
  end
end
