# frozen_string_literal: true

# == Schema Information
#
# Table name: ysws_review_devlog_approvals
#
#  id               :bigint           not null, primary key
#  approved         :boolean          not null
#  approved_seconds :integer
#  notes            :text
#  reviewed_at      :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  devlog_id        :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_ysws_review_devlog_approvals_on_devlog_id  (devlog_id) UNIQUE
#  index_ysws_review_devlog_approvals_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (devlog_id => devlogs.id)
#  fk_rails_...  (user_id => users.id)
#
class YswsReview::DevlogApproval < ApplicationRecord
  has_paper_trail

  self.table_name = "ysws_review_devlog_approvals"

  belongs_to :devlog
  belongs_to :user # The reviewer

  validates :approved, inclusion: { in: [ true, false ] }
  validates :reviewed_at, presence: true
  validates :approved_seconds, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :approved, -> { where(approved: true) }
  scope :rejected, -> { where(approved: false) }

  def seconds_changed?
    return false unless devlog.duration_seconds.present?

    approved_seconds != devlog.duration_seconds
  end

  def seconds_reduction
    return 0 unless devlog.duration_seconds.present? && approved_seconds.present?

    [ devlog.duration_seconds - approved_seconds, 0 ].max
  end

  def approval_status
    approved? ? "approved" : "rejected"
  end
end
