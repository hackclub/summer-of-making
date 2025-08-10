module Admin
  class StaticPagesController < ApplicationController
    before_action :auth, only: [ :index ]
    skip_before_action :authenticate_admin!

    def index
      render html: "<h1>bruh</h1>".html_safe unless current_user&.is_admin? || current_user&.fraud_team_member?

      # Generate data points for Payout.calculate_multiplier from 0 to 1 in steps of 0.01
      # @multiplier_data = (0..100).map do |i|
      #   x = i / 100.0
      #   [ x, Payout.calculate_multiplier(x) ]
      # end
    end

    private

    def auth
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end
  end
end
