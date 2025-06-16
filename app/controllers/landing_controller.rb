# frozen_string_literal: true

require "open-uri"
CHANNEL_LIST = [ "C015M4L9AHW", "C091CEEHJ9K", "C016DEDUL87", "C75M7C0SY", "C090JKDJYN8", "C090B3T9R9R", "C0M8PUPU6", "C05B6DBN802" ]
class LandingController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index sign_up]

  def index
    @high_seas_reviews = Rails.cache.fetch("high_seas_reviews", expires_in: 1.hour) do
      Airtable::HighSeasBook::StorySubmission.has_attached_photo.includes([ :photo_attachment ])
    end.sample(5)

    if user_signed_in?
      if current_user.tutorial_progress.completed_at.nil?
        redirect_to campfire_path
      else
        redirect_to explore_path
      end
    else
      ahoy.track "tutorial_step_landing_first_visit" unless ahoy.visitor_token.present?
    end

    @prizes = ShopItem.shown_in_carousel.order(ticket_cost: :asc).map do |item|
      hours = item.average_hours_estimated.to_i
      {
        name: item.name,
        time: "~#{hours} #{"hour".pluralize(hours)}",
        image: item.image.present? ? url_for(item.image) : "https://crouton.net/crouton.png",
        ticket_cost: item.ticket_cost
      }
    end
    # @prizes = [
    #   {
    #     name: "Flipper Zero Device",
    #     time: "~120 hours",
    #     image: "https://files.catbox.moe/eiflg8.png"
    #   },
    #   {
    #     name: "Framework Laptop 16",
    #     time: ">500 hours",
    #     image: "https://files.catbox.moe/g143bn.png"
    #   },
    #   {
    #     name: "3D Printer Filament",
    #     time: "~40 hours",
    #     image: "https://files.catbox.moe/9plgxa.png"
    #   },
    #   {
    #     name: "Pinecil Soldering Iron",
    #     time: "~30 hours",
    #     image: "https://files.catbox.moe/l6txpc.png"
    #   },
    #   {
    #     name: "Cloudflare Credits",
    #     time: "~50 hours",
    #     image: "https://files.catbox.moe/dlxfqe.png"
    #   },
    #   {
    #     name: "DigitalOcean Credits",
    #     time: "~60 hours",
    #     image: "https://files.catbox.moe/9rh45c.png"
    #   },
    #   {
    #     name: "JLCPCB Credits",
    #     time: "~30 hours",
    #     image: "https://files.catbox.moe/91z02d.png"
    #   },
    #   {
    #     name: "Digikey Credits",
    #     time: "~80 hours",
    #     image: "https://files.catbox.moe/8dmgvm.png"
    #   },
    #   {
    #     name: "Domain Registration",
    #     time: "~25 hours",
    #     image: "https://files.catbox.moe/523zji.png"
    #   },
    #   {
    #     name: "iPad with Apple Pencil",
    #     time: ">500 hours",
    #     image: "https://files.catbox.moe/44rj2b.png"
    #   },
    #   {
    #     name: "Mode Design Sonnet Keyboard",
    #     time: "~300 hours",
    #     image: "https://files.catbox.moe/r2f8ug.png"
    #   },
    #   {
    #     name: "GitHub Notebook",
    #     time: "~15 hours",
    #     image: "https://files.catbox.moe/l12lhl.png"
    #   },
    #   {
    #     name: "Raspberry Pi 5 Making Kit",
    #     time: "~90 hours",
    #     image: "https://files.catbox.moe/w3a964.png"
    #   },
    #   {
    #     name: "Raspberry Pi Zero 2 W Kit",
    #     time: "~35 hours",
    #     image: "https://files.catbox.moe/rcg0s0.png"
    #   },
    #   {
    #     name: "ThinkPad X1 (Renewed)",
    #     time: ">500 hours",
    #     image: "https://files.catbox.moe/fidiwz.png"
    #   },
    #   {
    #     name: "BLÅHAJ Soft Toy Shark",
    #     time: "~20 hours",
    #     image: "https://files.catbox.moe/h16yjs.png"
    #   },
    #   {
    #     name: "Sony XM4 Headphones",
    #     time: "~250 hours",
    #     image: "https://files.catbox.moe/vvn9cw.png"
    #   },
    #   {
    #     name: "Bose QuietComfort 45",
    #     time: "~280 hours",
    #     image: "https://files.catbox.moe/5i8ff8.png"
    #   },
    #   {
    #     name: "Logitech MX Master 3S Mouse",
    #     time: "~80 hours",
    #     image: "https://files.catbox.moe/iidxib.png"
    #   },
    #   {
    #     name: "Logitech Pro X Superlight Mouse",
    #     time: "~150 hours",
    #     image: "https://files.catbox.moe/uw1iu0.png"
    #   },
    #   {
    #     name: "Steam Game - Factorio",
    #     time: "~25 hours",
    #     image: "https://files.catbox.moe/ld6igi.png"
    #   },
    #   {
    #     name: "Steam Game - Satisfactory",
    #     time: "~30 hours",
    #     image: "https://files.catbox.moe/2zjc85.png"
    #   },
    #   {
    #     name: "Cricut Explore 3 Cutting Machine",
    #     time: "~180 hours",
    #     image: "https://files.catbox.moe/cydelv.png"
    #   },
    #   {
    #     name: "Yummy Fudge from HQ",
    #     time: "~35 hours",
    #     image: "https://files.catbox.moe/djmsr8.png"
    #   },
    #   {
    #     name: "Hack Club Sticker Pack",
    #     time: "~10 hours",
    #     image: "https://files.catbox.moe/uukr9a.png"
    #   },
    #   {
    #     name: "Speedcube",
    #     time: "~20 hours",
    #     image: "https://files.catbox.moe/sqltgo.png"
    #   },
    #   {
    #     name: "Personal Drawing from MSW",
    #     time: "~200 hours",
    #     image: "https://files.catbox.moe/aic9z4.png"
    #   },
    #   {
    #     name: "Random Object from HQ",
    #     time: "~15 hours",
    #     image: nil
    #   }
    # ]

    @prizes.map! do |prize|
      hours =
        if prize[:time].to_s.include?(">500")
          9999
        elsif prize[:time].to_s =~ /([0-9]+)/
          prize[:time].to_s.include?("~") ? $1.to_i : $1.to_i
        else
          0
        end
      prize.merge(
        numeric_hours: hours,
        display_time: hours >= 500 ? ">500 hours" : prize[:time],
        random_transform: "rotate(#{rand(-3..3)}deg) scale(#{(rand(97..103).to_f/100).round(2)}) translateY(#{rand(-8..8)}px)"
      )
    end

    @prizes = @prizes.sort_by { |p| [ p[:ticket_cost] || 0, p[:numeric_hours] ] }
  end

  def sign_up
    email = params.require(:email)

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

    EmailSignup.create!(email:, ip: request.remote_ip, user_agent: request.headers["User-Agent"])

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
    "?"
  end
end
