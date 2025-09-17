module Admin
  class StaticPagesController < ApplicationController
    before_action :auth, only: [ :index ]
    skip_before_action :authenticate_admin!

    def index
      render html: "<h1>bruh</h1>".html_safe unless current_user&.is_admin? || current_user&.fraud_team_member?

      @admin_signed_in = current_user.is_admin?
      @fraud_team_signed_in = current_user.fraud_team_member?
    end

    private

    def auth
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end
  end
end
