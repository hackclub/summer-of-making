module Admin
  class ShipReviewerPayoutRequestsController < ApplicationController
    before_action :authenticate_admin!
    before_action :set_payout_request, only: [ :show, :approve, :reject ]

    def index
      @pending_requests = ShipReviewerPayoutRequest.pending_requests
                                                   .includes(:reviewer)
                                                   .order(:requested_at)
      @recent_requests = ShipReviewerPayoutRequest.includes(:reviewer, :approved_by)
                                                  .order(created_at: :desc)
                                                  .limit(20)
    end

    def show
    end

    def approve
      @payout_request.approve!(current_user)
      redirect_to admin_ship_reviewer_payout_requests_path,
                  notice: "Payout request approved! #{@payout_request.amount} shells paid to #{@payout_request.reviewer.display_name || @payout_request.reviewer.email}"
    rescue => e
      redirect_to admin_ship_reviewer_payout_requests_path,
                  alert: "Error approving payout: #{e.message}"
    end

    def reject
      @payout_request.update!(
        status: :rejected,
        approved_by: current_user,
        approved_at: Time.current
      )
      redirect_to admin_ship_reviewer_payout_requests_path,
                  notice: "Payout request rejected"
    end

    private

    def set_payout_request
      @payout_request = ShipReviewerPayoutRequest.find(params[:id])
    end
  end
end
