module Admin
  class ApplicationController < ActionController::Base
    include PublicActivity::StoreController

    before_action :authenticate_admin!
    rescue_from StandardError, with: :handle_error if Rails.env.production?

    helper_method :current_user

    layout "admin"

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end

    private

    def handle_error(exception)
      uuid = Honeybadger.notify(exception)
      flash[:notice] = "oepsie woepsie, we made a f*cko boingo – look this up in honeybadger: #{uuid}"
      redirect_to admin_root_path
    end

    def authenticate_admin!
      redirect_to("https://www.youtube.com/watch?v=dQw4w9WgXcQ", allow_other_host: true) unless current_user&.is_admin?
    end
  end
end
