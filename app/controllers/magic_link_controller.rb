class MagicLinkController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_magic_token_service_agent
  skip_before_action :authenticate_user!, only: %i[get_secret_magic_url]

  def get_secret_magic_url
    slack_id = params.require(:slack_id)
    email = params.require(:email)

    signup = EmailSignup.find_or_create_by(email: email) do |s|
      s.slack_id = slack_id
      s.ip = request.remote_ip
      s.user_agent = request.user_agent
    end

    Rails.logger.info({ event: "created_email_signup", email: email, slack_id: slack_id, ip: request.remote_ip, user_agent: request.user_agent }.to_json)

    begin
      user = User.create_from_slack slack_id

      Rails.logger.tagged("MagicLink") do
        Rails.logger.info({
          event: "created_user",
          id: user.id,
          slack_id: user.slack_id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name
        }.to_json)
      end
    rescue StandardError => e
      Honeybadger.notify(e)
      user = User.find_by(email: email)
    end

    begin
      link = MagicLink.find_or_create_by(user: user).secret_url request.host
    rescue StandardError => e
      Honeybadger.notify(e)
      return render json: { success: false, error: "Failed to generate magic link." }, status: 500
    end

    render json: { success: true, link: link, ip: signup.ip, user_agent: signup.user_agent }
  end

  private

  def authenticate_magic_token_service_agent
    unless params.require(:token) == Rails.application.credentials.explorpheus.token
      render json: { success: false, error: "Unauthorized" }, status: :unauthorized
      nil
    end
  end
end
