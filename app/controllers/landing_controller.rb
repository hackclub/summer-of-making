# frozen_string_literal: true

require "open-uri"
CHANNEL_LIST = ["C08MYN7HVN2","C08N1NWKEF4","C016DEDUL87","C75M7C0SY", "C090JKDJYN8", "C090B3T9R9R"]
class LandingController < ApplicationController
  def index
    redirect_to explore_path if user_signed_in?
    @prizes = [
      {
        name: "Flipper Zero",
        cost: 120,
        time: "~120 hours",
        image: "https://files.catbox.moe/3xaxax.png"
      },
      {
        name: "Framework Laptop 16",
        cost: 800,
        time: "~800 hours",
        image: "https://files.catbox.moe/tyvnfm.png"
      },
      {
        name: "3D Printer Filament Bundle",
        cost: 40,
        time: "~40 hours",
        image: "https://files.catbox.moe/momszq.png"
      },
      {
        name: "Pinecil Soldering Iron",
        cost: 30,
        time: "~30 hours",
        image: "https://files.catbox.moe/g796u0.png"
      },
      {
        name: "Cloudflare Credits",
        cost: 50,
        time: "~50 hours",
        image: "https://files.catbox.moe/dlxfqe.png"
      },
      {
        name: "GitHub Codespaces Credits",
        cost: 75,
        time: "~75 hours",
        image: "https://files.catbox.moe/m2d3g6.png"
      },
      {
        name: "DigitalOcean Credits",
        cost: 60,
        time: "~60 hours",
        image: "https://files.catbox.moe/9rh45c.png"
      },
      {
        name: "PCB Credits - JLCPCB",
        cost: 30,
        time: "~30 hours",
        image: "https://files.catbox.moe/91z02d.png"
      },
      {
        name: "Electronics Credits - Digikey",
        cost: 80,
        time: "~80 hours",
        image: "https://files.catbox.moe/8dmgvm.png"
      },
      {
        name: "Domain Registration Credits",
        cost: 25,
        time: "~25 hours",
        image: "https://files.catbox.moe/7t427r.png"
      },
      {
        name: "iPad with Apple Pencil",
        cost: 450,
        time: "~450 hours",
        image: "https://files.catbox.moe/t5bh39.png"
      },
      {
        name: "Mode Design Sonnet Keyboard",
        cost: 300,
        time: "~300 hours",
        image: "https://files.catbox.moe/6iq56a.png"
      },
      {
        name: "Ben Eater 8-bit Computer Kit",
        cost: 200,
        time: "~200 hours",
        image: "https://files.catbox.moe/5z0gzz.png"
      },
      {
        name: "Raspberry Pi 5",
        cost: 90,
        time: "~90 hours",
        image: "https://files.catbox.moe/343tqt.png"
      },
      {
        name: "Raspberry Pi Zero 2 W",
        cost: 35,
        time: "~35 hours",
        image: "https://files.catbox.moe/lfml8k.png"
      },
      {
        name: "ThinkPad X1 Carbon (Renewed)",
        cost: 600,
        time: "~600 hours",
        image: "https://files.catbox.moe/m2r3md.png"
      },
      {
        name: "BLÅHAJ Soft Toy",
        cost: 20,
        time: "~20 hours",
        image: "https://files.catbox.moe/g7vbdo.png"
      },
      {
        name: "Sony WH-1000XM4 Headphones",
        cost: 250,
        time: "~250 hours",
        image: "https://files.catbox.moe/o210o5.png"
      },
      {
        name: "Bose QuietComfort 45",
        cost: 280,
        time: "~280 hours",
        image: "https://files.catbox.moe/zpf595.png"
      },
      {
        name: "Logitech MX Master 3S Mouse",
        cost: 80,
        time: "~80 hours",
        image: "https://files.catbox.moe/oz5ey8.png"
      },
      {
        name: "Logitech Pro X Superlight Mouse",
        cost: 150,
        time: "~150 hours",
        image: "https://files.catbox.moe/34ncyk.png"
      },
      {
        name: "Steam Game - Factorio",
        cost: 25,
        time: "~25 hours",
        image: "https://files.catbox.moe/ld6igi.png"
      },
      {
        name: "Steam Game - Satisfactory",
        cost: 30,
        time: "~30 hours",
        image: "https://files.catbox.moe/2zjc85.png"
      },
      {
        name: "Cricut Explore 3",
        cost: 180,
        time: "~180 hours",
        image: "https://files.catbox.moe/1trazc.png"
      },
      {
        name: "MORE FUDGE!",
        cost: 35,
        time: "~35 hours",
        image: "https://files.catbox.moe/djmsr8.png"
      },
      {
        name: "Hack Club Sticker Pack",
        cost: 10,
        time: "~10 hours",
        image: "https://files.catbox.moe/hx87j5.png"
      },
      {
        name: "Signed Photo of Zack Latta",
        cost: 100,
        time: "~100 hours",
        image: "https://files.catbox.moe/1e4e17.png"
      },
      {
        name: "Personal Drawing from MSW",
        cost: 200,
        time: "~200 hours",
        image: "https://files.catbox.moe/xxug1g.png"
      },
      {
        name: "Random Object from HQ",
        cost: 15,
        time: "~15 hours",
        image: nil
      },
      {
        name: "Bottom Half of Chromebook",
        cost: 25,
        time: "~25 hours",
        image: nil
      },
      {
        name: "Mystery eBay Treasure",
        cost: 30,
        time: "~30 hours",
        image: "https://files.catbox.moe/m9n9vj.png"
      },
      {
        name: "Top Half of Chromebook",
        cost: 25,
        time: "~25 hours",
        image: "https://files.catbox.moe/kv740i.png"
      },
      {
        name: "Bottom Half of Chromebook",
        cost: 30,
        time: "~30 hours",
        image: "https://files.catbox.moe/h7vt5n.png"
      }
    ]
  end

  def sign_up
    email = params.require(:email)

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return respond_to do |format|
        format.html { redirect_to request.referer || projects_path, alert: "Invalid email format" }
        format.turbo_stream do
          flash.now[:alert] = "Invalid email format"
          render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash"),
                 status: :internal_server_error
        end
      end
    end

    EmailSignup.create!(email:)

    slack_invite_response = send_slack_invite(email)

    Rails.logger.debug { "Status: #{slack_invite_response.code}" }
    Rails.logger.debug { "Body:\n#{slack_invite_response.body}" }

    body = JSON.parse(slack_invite_response.body)
    Rails.logger.debug body

    @response_data = body

    respond_to do |format|
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
    token:  ENV["SLACK_XOXC"],
    email: email,
    invites: [
    {
      email: email,
      type: 'restricted',
      mode: 'manual'
    }
  ],
    restricted: true,
    channels: CHANNEL_LIST          
  }
  uri = URI.parse("https://slack.com/api/users.admin.inviteBulk")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true


  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Cookie'] = "d=#{ENV['SLACK_XOXD']}"
  request['Authorization'] = "Bearer #{ENV["SLACK_XOXC"]}"  
  request.body = JSON.generate(payload)

# Send the request
  response = http.request(request)
  response.body
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
