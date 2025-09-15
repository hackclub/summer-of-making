# frozen_string_literal: true

require "open-uri"
CHANNEL_LIST = %w[C015M4L9AHW C091CEEHJ9K C090JKDJYN8 C090B3T9R9R C092833JXKK]

class LandingController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index sign_up]

  def index
    # @high_seas_reviews = Rails.cache.fetch("high_seas_reviews", expires_in: 1.hour) do
    #   Airtable::HighSeasBook::StorySubmission.has_attached_photo.includes([ :photo_attachment ])
    # end.sample(5)

    if user_signed_in?
      redirect_to explore_path
      # if current_user.tutorial_progress.completed_at.nil?
      #   redirect_to campfire_path
      # else
      #   redirect_to explore_path
      # end
    else
      ahoy.track "tutorial_step_landing_first_visit"

      @prizes = Cache::CarouselPrizesJob.perform_now
    end
  end

  def sign_up
    email = params.require(:email).downcase
    ref = params[:ref]

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return respond_to do |format|
        format.html { redirect_to request.referer || projects_path, alert: "Invalid email format" }
        format.json { render json: { ok: false, error: "Invalid email format" }, status: :bad_request }
        format.turbo_stream do
          flash.now[:alert] = "Invalid email format"
          render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash"),
                 status: :internal_server_error
        end
      end
    end

    # Creating multiple email signups per address could be used for referral fraud
    EmailSignup.find_or_create_by(email:) do |signup|
      signup.ref = ref
      signup.ip = request.remote_ip
      signup.user_agent = request.headers["User-Agent"]
    end

    ahoy.track "tutorial_step_email_signup", email: email

    slack_invite_response = send_slack_invite(email)

    Rails.logger.debug { "Status: #{slack_invite_response.code}" }
    Rails.logger.debug { "Body:\n#{slack_invite_response.body}" }

    body = JSON.parse(slack_invite_response.body)
    Rails.logger.debug body

    @response_data = body.merge("email" => email)

    respond_to do |format|
      format.json { render json: @response_data }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("modal-content", partial: "landing/signup_modal"),
          turbo_stream.action("show_modal", "signup-modal")
        ]
      end
    end
  end

  private

  def send_slack_invite(email)
    payload = {
      token: Rails.application.credentials.explorpheus.slack_xoxc,
      email: email,
      invites: [
        {
          email: email,
          type: "restricted",
          mode: "manual"
        }
      ],
      restricted: true,
      channels: CHANNEL_LIST
    }
    uri = URI.parse("https://slack.com/api/users.admin.inviteBulk")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Cookie"] = "d=#{Rails.application.credentials.explorpheus.slack_xoxd}"
    request["Authorization"] = "Bearer #{Rails.application.credentials.explorpheus.slack_xoxc}"
    request.body = JSON.generate(payload)

    # Send the request
    response = http.request(request)
    response
  end

  def fetch_continent(ip)
    response = URI.open("https://ip.hackclub.com/ip/#{ip}").read
    return "?" if response.blank?

    data = JSON.parse(response)
    data["continent_name"] || data["continent_code"] || "?"
  rescue StandardError => e
    Rails.logger.error "IP lookup failed: #{e.message}"
    Honeybadger.notify(e)
    "?"
  end
end
