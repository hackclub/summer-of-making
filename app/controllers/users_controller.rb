# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_api_key, only: [ :check_user ]
  before_action :authenticate_user!,
                only: %i[update_hackatime_confirmation refresh_hackatime check_hackatime_connection]

  def check_user
    user = User.find_by(slack_id: params[:slack_id])

    if user&.projects&.any?
      render json: { exists: true, has_project: true, projects: user.projects }, status: :ok
    elsif user
      render json: { exists: true, has_project: false }, status: :ok
    else
      render json: { exists: false, has_project: false }, status: :not_found
    end
  end

  def refresh_hackatime
    current_user.refresh_hackatime_data
    redirect_back_or_to root_path,
                        notice: "Hackatime data refresh has been initiated. It may take a few moments to complete."
  end

  def check_hackatime_connection
    User.check_hackatime(current_user.slack_id)

    current_user.reload

    if current_user.has_hackatime
      redirect_back_or_to root_path,
                          notice: "Successfully connected to Hackatime! Your coding stats are now being tracked."
    else
      redirect_back_or_to root_path,
                          alert: "No Hackatime connection found. Please sign up at Hackatime with your Slack account and try again."
    end
  end

  def identity_vault_callback
    current_user.link_identity_vault_callback(identity_vault_callback_url, params[:code])
    redirect_to order_shop_item_path(ShopItem::FreeStickers.first), notice: "Successfully linked your identity!"
  end

  def link_identity_vault
    return redirect_to root_path unless current_verification_status == :not_linked

    redirect_to current_user.identity_vault_oauth_link(identity_vault_callback_url), allow_other_host: true
  end

  def hackatime_auth_redirect
    redirect_to root_path, notice: "huh?" if current_user.has_hackatime?
    res = Faraday.new do |f|
      f.request :url_encoded
      f.response :json, parser_options: { symbolize_names: true }
      f.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:hackatime, :internal_key)}"
    end
           .post(
             "https://hackatime.hackclub.com/api/internal/can_i_have_a_magic_link_for/#{current_user.slack_id}",
             {
               email: current_user.email,
               return_data: {
                 url: campfire_url,
                 button_text: "head back to Summer of Making!"
               }
             }
           ).body
    pp res
    redirect_to res[:magic_link] || root_path, allow_other_host: true
  end

  private

  def authenticate_api_key
    api_key = request.headers["Authorization"]
    return if api_key.present? && api_key == ENV["API_KEY"]

    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
