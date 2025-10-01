# == Schema Information
#
# Table name: ship_reviewer_payout_requests
#
#  id              :bigint           not null, primary key
#  amount          :decimal(, )
#  approved_at     :datetime
#  decisions_count :integer
#  multiplier      :decimal(4, 2)    default(1.0)
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

  def self.calculate_amount_for_decisions(decisions_count, reviewer: nil)
    if reviewer
      # Get reviewer's position in weekly leaderboard
      position = get_reviewer_position(reviewer)
      result = ShipReviewerMultiplierService.calculate_multiplier_and_effective_rate_for_position(position)
      multiplier = result[:multiplier]
      effective_rate = result[:effective_rate]

      # Return both amount and multiplier for storage
      {
        amount: decisions_count * effective_rate,
        multiplier: multiplier,
        position: position
      }
    else
      # Fall back to base rate if no reviewer provided
      {
        amount: decisions_count * ShipReviewerMultiplierService::BASE_SHELLS_PER_REVIEW,
        multiplier: 1.0,
        position: nil
      }
    end
  end

  private

  def self.get_reviewer_position(reviewer)
    # Calculate this week's Sunday in EST (same logic as controller)
    est_zone = ActiveSupport::TimeZone.new("America/New_York")
    current_est = Time.current.in_time_zone(est_zone)
    week_start = current_est.beginning_of_week(:sunday)

    # Get weekly leaderboard with consistent logic from ship_certifications_controller
    weekly_leaderboard = User.joins("INNER JOIN ship_certifications ON users.id = ship_certifications.reviewer_id")
      .joins("INNER JOIN projects ON ship_certifications.project_id = projects.id")
      .where.not(ship_certifications: { reviewer_id: nil })
      .where("ship_certifications.updated_at >= ?", week_start)
      .where("ship_certifications.updated_at >= ship_certifications.created_at")
      .where.not(ship_certifications: { judgement: :pending })
      .where(projects: { is_deleted: false })
      .group("users.id")
      .order("COUNT(ship_certifications.id) DESC")
      .pluck("users.id", "COUNT(ship_certifications.id)")

    # Find reviewer's position (1-indexed)
    position = weekly_leaderboard.find_index { |user_id, _count| user_id == reviewer.id }
    position ? position + 1 : nil
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
