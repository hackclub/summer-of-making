# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include PublicActivity::StoreController
  include Pundit::Authorization

  # before_action :try_rack_mini_profiler_enable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action do
    Rails.logger.info ">>> Session[:user_id] = #{session[:user_id]}"
    Rails.logger.info ">>> Current user ID: #{current_user&.id}"
    Rails.logger.info ">>> Request IP: #{request.remote_ip}, User-Agent: #{request.user_agent}"
  end

  before_action :authenticate_user!
  before_action :check_if_banned
  before_action :fetch_hackatime_data_if_needed
  after_action :track_page_view

  helper_method :current_user, :user_signed_in?, :current_verification_status, :current_impersonator, :impersonating?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_impersonator
    @current_impersonator ||= User.find_by(id: session[:impersonator_user_id]) if session[:impersonator_user_id]
  end

  def current_verification_status
    @current_verification_status ||= current_user&.verification_status
  end

  def user_signed_in?
    !!current_user
  end

  def impersonating?
    !!current_impersonator
  end

  def authenticate_user!
    redirect_to root_path, alert: "Please sign in to access this page" unless user_signed_in?
  end

  def check_if_banned
    return unless user_signed_in?
    return false if current_user.is_banned?.nil?
    return unless current_user.is_banned?

    unless controller_name == "campfire"
      redirect_to campfire_path, alert: "You can not access this!"
    end
  end

  def require_admin!
    redirect_to "/" unless current_user && current_user.is_admin?
  end

  private

  def try_rack_mini_profiler_enable
    if current_user && current_user.is_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  def fetch_hackatime_data_if_needed
    return if !user_signed_in? || current_user.hackatime_projects.any?

    current_user.refresh_hackatime_data_now
  end

  def track_page_view
    ahoy.track "$view", {
      controller: params[:controller],
      action: params[:action],
      user_id: current_user&.id
    }
  end
end
