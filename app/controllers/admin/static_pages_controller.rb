module Admin
  class StaticPagesController < ApplicationController
    skip_before_action :authenticate_admin!, only: [ :index ]

    def index
    return render html: "<h1>bruh</h1>".html_safe unless current_user&.is_admin

    # Generate data points for Payout.calculate_multiplier from 0 to 1 in steps of 0.01
    @multiplier_data = (0..100).map do |i|
      x = i / 100.0
      [ x, Payout.calculate_multiplier(x) ]
    end
  end
  end
end
