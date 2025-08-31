# frozen_string_literal: true

module Api
  module V2
    class PayoutsController < BaseController
      def index
        payouts = Payout.includes(:user)
                        .order(id: :desc)

        render_paginated(payouts) do |payout|
          ip(payout)
        end
      end

      def show
        payout = Payout.includes(:user)
                      .find_by(id: params[:id])

        return render_not_found("not found") unless payout

        render json: ip(payout)
      end

      private

      def ip(payout)
        {
          id: payout.id,
          amount: payout.amount,
          escrowed: payout.escrowed,
          payable_type: payout.payable_type,
          user: {
            id: payout.user.id,
            display_name: payout.user.display_name
          },
          created_at: payout.created_at
        }
      end
    end
  end
end
