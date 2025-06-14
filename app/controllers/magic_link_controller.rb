class MagicLinkController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_magic_token_service_agent
  skip_before_action :authenticate_user!, only: %i[get_secret_magic_url]

  def get_secret_magic_url
    slack_id = params.require(:slack_id)
    email = params.require(:email)

    signup = EmailSignup.find_by(email:)
    return render json: { success: false, error: "No email sign up found. Are you URL encoding the email?" }, status: 400 if signup.nil?

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
      user = User.find_by(email:)
    end

    link = MagicLink.find_or_create_by(user:).secret_url request.host

    render json: { success: true, link:, ip: signup.ip, user_agent: signup.user_agent }
  end

  private

  def authenticate_magic_token_service_agent
    unless params.require(:token) == Rails.application.credentials.explorpheus.token
      render json: { success: false, error: "Unauthorized" }, status: :unauthorized
      nil
    end
  end
end
