# frozen_string_literal: true

class Rack::Attack
  Rack::Attack.safelist("allow-localhost") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip
  end

  Rack::Attack.throttle("fuck scrapers", limit: 400, period: 1.hour) do |req|
    req.ip if req.path.start_with?("/api/")
    req.ip if req.path.start_with?("/shop")
    req.ip if req.path.start_with?("/votes")
    req.ip if req.path == "/leaderboard"
  end

  self.throttled_responder = lambda do |env|
    r = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => r.to_s
      },
      [ { ok: false, message: "stop spamming us" }.to_json ]
    ]
  end
end
