# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include PublicActivity::StoreController
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action do
    Rails.logger.info ">>> Session[:user_id] = #{session[:user_id]}"
    Rails.logger.info ">>> Current user ID: #{current_user&.id}"
    Rails.logger.info ">>> Request IP: #{request.remote_ip}, User-Agent: #{request.user_agent}"
  end

  before_action :fetch_hackatime_data_if_needed

  helper_method :current_user, :user_signed_in?, :current_verification_status

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_verification_status
    @current_verification_status ||= current_user&.verification_status
  end

  def user_signed_in?
    !!current_user
  end

  def authenticate_user!
    redirect_to root_path, alert: "Please sign in to access this page" unless user_signed_in?
  end

  private

  def fetch_hackatime_data_if_needed
    return unless user_signed_in?
    return if current_user.has_hackatime?

    Rails.cache.fetch("hackatime_fetch_#{current_user.id}", expires_in: 5.seconds) do
      current_user.refresh_hackatime_data_now
    end
  end
end
