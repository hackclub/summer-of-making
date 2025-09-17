# == Schema Information
#
# Table name: ship_reviewer_payout_requests
#
#  id              :bigint           not null, primary key
#  amount          :decimal(, )
#  approved_at     :datetime
#  decisions_count :integer
#  requested_at    :datetime
#  status          :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approved_by_id  :bigint
#  reviewer_id     :bigint           not null
#
# Indexes
#
#  index_ship_reviewer_payout_requests_on_approved_by_id  (approved_by_id)
#  index_ship_reviewer_payout_requests_on_reviewer_id     (reviewer_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (reviewer_id => users.id)
#
class ShipReviewerPayoutRequest < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :decisions_count, presence: true, numericality: { greater_than: 0 }

  scope :for_reviewer, ->(user) { where(reviewer: user) }
  scope :pending_requests, -> { where(status: :pending) }

  def self.calculate_amount_for_decisions(decisions_count)
    (decisions_count / 2) * 0.5
  end

  def approve!(approver)
    transaction do
      update!(
        status: :approved,
        approved_by: approver,
        approved_at: Time.current
      )

      Payout.create!(
        user: reviewer,
        amount: amount,
        reason: "Ship certification review payment: #{decisions_count} decisions",
        payable: reviewer
      )
    end
  end
end
