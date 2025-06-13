# frozen_string_literal: true

require "open-uri"
CHANNEL_LIST = [ "C091CEW2CN9", "C091CEW2CN9", "C016DEDUL87", "C75M7C0SY", "C090JKDJYN8", "C090B3T9R9R", "C0M8PUPU6", "C05B6DBN802" ]
class LandingController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index sign_up]

  def index
    @high_seas_reviews = [
      { text: "I joined Hack Club back in July, but to be honest, I didn’t totally get how it all worked at first. Then around November, I saw that High Seas had started and decided to sign up. I checked out the YSWS projects (can’t really remember what was up at the time), but one that caught my eye was Browser Buddy. I ended up spending over 12 hours on it, even though I still couldn’t figure out how the MV3 API works 😅.", image: "https://v5.airtableusercontent.com/v3/u/42/42/1749837600000/6ioLYZabCvaEQhtrzuEa0g/qtpC2rYSKi0HBPcR9EhILYbkUnCe4YWvNzS57cdln00cwXhPra9zmSG_4JsivEpgWPPwqFzJAZJ2XetcnS9CJt87LoGOi4s8onvEWGcuH3-RHSCrpZMZdP8vwaCiho5i2X7rIULedXIJEjgAf9juJA/--u6P5kh4mQX7Kb_Nw7WAZ6jwhOFHZZPROO1nvFIL1A" },
      { text: "High Seas really helped me get consistent with coding—now I’m basically coding every day. And getting a new mouse in the mail was such an exciting bonus!", image: "https://v5.airtableusercontent.com/v3/u/42/42/1749837600000/B60VyBKYiXCI4RFMomciMw/Ev05FpSunc3QvfuuY-VjUO49RVVFuLTl7dEr2QWg3zYndHe8Ug82_4Hz-dioEr6gWC0RGfJEkmTKOalTuYl3bxRf5Z9y_lMrL-lZRicMH6EdAoDspLdrUaL1WVbdW2j0JKkCHgJAurwYE4jAXcbXmg/3xscQ5gkMcGdFcWl6cBg1E7AH0yNxZQvKSw8EUHW78Y" }
    ]

    if user_signed_in?
      if current_user.tutorial_progress.completed_at.nil?
        redirect_to campfire_path
      else
        redirect_to explore_path
      end
    end

    @prizes = [
      {
        name: "Flipper Zero Device",
        time: "~120 hours",
        image: "https://files.catbox.moe/eiflg8.png"
      },
      {
        name: "Framework Laptop 16",
        time: ">500 hours",
        image: "https://files.catbox.moe/g143bn.png"
      },
      {
        name: "3D Printer Filament",
        time: "~40 hours",
        image: "https://files.catbox.moe/9plgxa.png"
      },
      {
        name: "Pinecil Soldering Iron",
        time: "~30 hours",
        image: "https://files.catbox.moe/l6txpc.png"
      },
      {
        name: "Cloudflare Credits",
        time: "~50 hours",
        image: "https://files.catbox.moe/dlxfqe.png"
      },
      {
        name: "DigitalOcean Credits",
        time: "~60 hours",
        image: "https://files.catbox.moe/9rh45c.png"
      },
      {
        name: "JLCPCB Credits",
        time: "~30 hours",
        image: "https://files.catbox.moe/91z02d.png"
      },
      {
        name: "Digikey Credits",
        time: "~80 hours",
        image: "https://files.catbox.moe/8dmgvm.png"
      },
      {
        name: "Domain Registration",
        time: "~25 hours",
        image: "https://files.catbox.moe/523zji.png"
      },
      {
        name: "iPad with Apple Pencil",
        time: ">500 hours",
        image: "https://files.catbox.moe/44rj2b.png"
      },
      {
        name: "Mode Design Sonnet Keyboard",
        time: "~300 hours",
        image: "https://files.catbox.moe/r2f8ug.png"
      },
      {
        name: "GitHub Notebook",
        time: "~15 hours",
        image: "https://files.catbox.moe/l12lhl.png"
      },
      {
        name: "Raspberry Pi 5 Making Kit",
        time: "~90 hours",
        image: "https://files.catbox.moe/w3a964.png"
      },
      {
        name: "Raspberry Pi Zero 2 W Kit",
        time: "~35 hours",
        image: "https://files.catbox.moe/rcg0s0.png"
      },
      {
        name: "ThinkPad X1 (Renewed)",
        time: ">500 hours",
        image: "https://files.catbox.moe/fidiwz.png"
      },
      {
        name: "BLÅHAJ Soft Toy Shark",
        time: "~20 hours",
        image: "https://files.catbox.moe/h16yjs.png"
      },
      {
        name: "Sony XM4 Headphones",
        time: "~250 hours",
        image: "https://files.catbox.moe/vvn9cw.png"
      },
      {
        name: "Bose QuietComfort 45",
        time: "~280 hours",
        image: "https://files.catbox.moe/5i8ff8.png"
      },
      {
        name: "Logitech MX Master 3S Mouse",
        time: "~80 hours",
        image: "https://files.catbox.moe/iidxib.png"
      },
      {
        name: "Logitech Pro X Superlight Mouse",
        time: "~150 hours",
        image: "https://files.catbox.moe/uw1iu0.png"
      },
      {
        name: "Steam Game - Factorio",
        time: "~25 hours",
        image: "https://files.catbox.moe/ld6igi.png"
      },
      {
        name: "Steam Game - Satisfactory",
        time: "~30 hours",
        image: "https://files.catbox.moe/2zjc85.png"
      },
      {
        name: "Cricut Explore 3 Cutting Machine",
        time: "~180 hours",
        image: "https://files.catbox.moe/cydelv.png"
      },
      {
        name: "Yummy Fudge from HQ",
        time: "~35 hours",
        image: "https://files.catbox.moe/djmsr8.png"
      },
      {
        name: "Hack Club Sticker Pack",
        time: "~10 hours",
        image: "https://files.catbox.moe/uukr9a.png"
      },
      {
        name: "Speedcube",
        time: "~20 hours",
        image: "https://files.catbox.moe/sqltgo.png"
      },
      {
        name: "Personal Drawing from MSW",
        time: "~200 hours",
        image: "https://files.catbox.moe/aic9z4.png"
      },
      {
        name: "Random Object from HQ",
        time: "~15 hours",
        image: nil
      }
    ]

    @prizes = @prizes.map do |prize|
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

    @prizes = @prizes.sort_by { |p| p[:numeric_hours] }
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
