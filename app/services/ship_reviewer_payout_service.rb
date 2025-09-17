class ShipReviewerPayoutService
  def self.can_request_payout?(reviewer)
    unpaid_decisions = count_unpaid_decisions(reviewer)
    unpaid_decisions >= 2 && !has_pending_request?(reviewer)
  end

  def self.request_payout(reviewer)
    return { success: false, error: "Not eligible for payout" } unless can_request_payout?(reviewer)

    unpaid_decisions = count_unpaid_decisions(reviewer)
    payable_decisions = (unpaid_decisions / 2) * 2 # Only pay for complete pairs
    amount = ShipReviewerPayoutRequest.calculate_amount_for_decisions(payable_decisions)

    request = ShipReviewerPayoutRequest.create!(
      reviewer: reviewer,
      amount: amount,
      decisions_count: payable_decisions,
      status: :pending,
      requested_at: Time.current
    )

    { success: true, request: request }
  end

  private

  def self.count_unpaid_decisions(reviewer)
    # Count decisions made by this reviewer since the payout system was implemented
    # Only count decisions made after September 3, 2025 (when this feature went live)
    feature_launch_date = Date.new(2025, 9, 3).beginning_of_day

    total_decisions = ShipCertification
      .unscoped
      .joins(:project)
      .where(reviewer: reviewer)
      .where.not(judgement: :pending)
      .where("ship_certifications.updated_at > ship_certifications.created_at")
      .where("ship_certifications.updated_at >= ?", feature_launch_date)
      .where(projects: { is_deleted: false })
      .count

    # Count decisions already paid for
    paid_decisions = Payout
      .where(user: reviewer, payable: reviewer)
      .where("reason LIKE ?", "Ship certification review payment:%")
      .pluck(:reason)
      .map { |reason| reason.scan(/(\d+) decisions/).flatten.first&.to_i || 0 }
      .sum

    # Count decisions in approved payout requests
    approved_requests_decisions = ShipReviewerPayoutRequest
      .where(reviewer: reviewer, status: :approved)
      .sum(:decisions_count)

    # Count decisions in pending payout requests
    pending_requests_decisions = ShipReviewerPayoutRequest
      .where(reviewer: reviewer, status: :pending)
      .sum(:decisions_count)

    # Return truly unpaid decisions
    total_decisions - paid_decisions - approved_requests_decisions - pending_requests_decisions
  end

  def self.has_pending_request?(reviewer)
    ShipReviewerPayoutRequest.where(reviewer: reviewer, status: :pending).exists?
  end
end
