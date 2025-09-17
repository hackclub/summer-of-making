class ShipReviewerPayoutRequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    result = ShipReviewerPayoutService.request_payout(current_user)

    if result[:success]
      redirect_back(fallback_location: admin_ship_certifications_path,
                   notice: "Payout request submitted! Amount: #{result[:request].amount} shells for #{result[:request].decisions_count} decisions.")
    else
      redirect_back(fallback_location: admin_ship_certifications_path,
                   alert: result[:error])
    end
  end

  def index
    @pending_requests = ShipReviewerPayoutRequest.pending_requests
                                                 .includes(:reviewer)
                                                 .order(:requested_at)
    @my_requests = ShipReviewerPayoutRequest.for_reviewer(current_user)
                                           .order(created_at: :desc)
                                           .limit(10)
  end
end
