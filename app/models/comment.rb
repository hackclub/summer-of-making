# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id           :bigint           not null, primary key
#  content      :text
#  rich_content :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  devlog_id    :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_comments_on_devlog_id  (devlog_id)
#  index_comments_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (devlog_id => devlogs.id)
#  fk_rails_...  (user_id => users.id)
#
class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :devlog, counter_cache: true

  validates :content, presence: true, length: { maximum: 1000 }, format: { with: /\A[^<>]*\z/, message: "must not contain HTML tags" }

  after_create :notify_devlog_author
  after_create :update_commenter_badges

  def display_content
    content.to_s
  end

  private

  def notify_devlog_author
    return if devlog.user.slack_id.blank?
    return if Rails.env.development?
    return unless devlog.project # Skip if project is nil

    message = "New comment on your project!:dino-bbq:\n\nCheck it out here: #{Rails.application.routes.url_helpers.project_url(
      devlog.project, host: ENV.fetch('APP_HOST', nil)
    )}"
    SendSlackDmJob.perform_later(devlog.user.slack_id, message)
  end

  def update_commenter_badges = AwardBadgesJob.perform_later(user_id)
end
