# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[new create failure magic_link auto_login_dev]

  def new
    state = SecureRandom.hex(24)
    session[:state] = state
    params = {
      client_id: ENV.fetch("SLACK_CLIENT_ID", nil),
      redirect_uri: slack_callback_url,
      state: state,
      user_scope: "identity.basic,identity.email,identity.team,identity.avatar",
      team: "T0266FRGM" # Hardcoding this because it will literally never, ever change.
    }
    redirect_to "https://slack.com/oauth/v2/authorize?#{params.to_query}", allow_other_host: true
  end

  def create
    if params[:state] != session[:state]
      Rails.logger.tagged("Authentication") do
        Rails.logger.error({
          event: "csrf_validation_failed",
          expected_state: session[:state],
          received_state: params[:state]
        }.to_json)
      end
      session[:state] = nil
      redirect_to root_path, alert: "Authentication failed. Possible CSRF"
      return
    end

    begin
      user = User.exchange_slack_token(params[:code], slack_callback_url)
      session[:user_id] = user.id

      Rails.logger.tagged("Authentication") do
        Rails.logger.info({
          event: "authentication_successful",
          user_id: user.id,
          slack_id: user.slack_id
        }.to_json)
      end

      ahoy.track "tutorial_step_slack_signin", user_id: user.id

      redirect_to root_path
    rescue StandardError => e
      Rails.logger.tagged("Authentication") do
        Rails.logger.error({
          event: "authentication_failed",
          error: e.message
        }.to_json)
      end
      redirect_to root_path, alert: e.message
    end
  end

  def failure
    Rails.logger.tagged("Authentication") do
      Rails.logger.error({
        event: "authentication_failed",
        error: "OAuth failure callback"
      }.to_json)
    end
    redirect_to root_path, alert: "Authentication failed."
  end

  def destroy
    Rails.logger.tagged("Authentication") do
      Rails.logger.info({
        event: "user_signed_out",
        user_id: session[:user_id]
      }.to_json)
    end
    session[:user_id] = nil
    redirect_to root_path, notice: "Signed out successfully!"
  end

  def magic_link
    token = params[:token]

    if token.blank?
      redirect_to root_path, alert: "Invalid magic link."
      return
    end

    magic_link = MagicLink.find_by(token: token)

    if magic_link.nil?
      Rails.logger.tagged("Authentication") do
        Rails.logger.warn({
          event: "magic_link_not_found",
          token: token
        }.to_json)
      end
      redirect_to root_path, alert: "Invalid magic link."
      return
    end

    if magic_link.expired?
      Rails.logger.tagged("Authentication") do
        Rails.logger.warn({
          event: "magic_link_expired",
          magic_link_id: magic_link.id,
          expired_at: magic_link.expires_at
        }.to_json)
      end
      redirect_to root_path, alert: "This magic link has expired."
      return
    end

    # Authenticate the user
    session[:user_id] = magic_link.user.id

    Rails.logger.tagged("Authentication") do
      Rails.logger.info({
        event: "magic_link_authentication_successful",
        user_id: magic_link.user.id,
        magic_link_id: magic_link.id
      }.to_json)
    end

    ahoy.track "tutorial_step_magic_link_signin", user_id: magic_link.user.id

    redirect_to root_path
  end

  def auto_login_dev
    # Only allow this in development environment for security
    unless Rails.env.development?
      redirect_to root_path, alert: "Not available in production"
      return
    end

    user = User.find_by(id: 1)
    if user
      session[:user_id] = user.id
      Rails.logger.tagged("Authentication") do
        Rails.logger.info({
          event: "auto_login_dev_successful",
          user_id: user.id,
          display_name: user.display_name
        }.to_json)
      end
      redirect_to root_path, notice: "Auto-logged in as #{user.display_name}!"
    else
      redirect_to root_path, alert: "User 1 not found"
    end
  end

  def stop_impersonating
    unless impersonating?
      flash[:alert] = "huh??"
      return redirect_to root_path
    end
    current_user.create_activity("stop_impersonating", owner: current_impersonator)
    session[:user_id] = session[:impersonator_user_id]
    session[:impersonator_user_id] = nil
    redirect_to root_path, notice: "welcome back, 007!"
  end
end
