class TurnstileService
  VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  def self.enabled?
    ENV["TURNSTILE_SECRET_KEY"].present?
  end

  def self.verify(response_token, remote_ip: nil)
    return { success: true, skipped: true } unless enabled?

    return { success: false, error: "missing_token" } if response_token.blank?

    payload = {
      secret: ENV["TURNSTILE_SECRET_KEY"],
      response: response_token
    }
    payload[:remoteip] = remote_ip if remote_ip.present?

    begin
      response = Faraday.post(
        VERIFY_URL,
        URI.encode_www_form(payload),
        "Content-Type" => "application/x-www-form-urlencoded"
      )
      body = JSON.parse(response.body) rescue {}
      success = body["success"] == true
      { success: success, body: body }
    rescue => e
      Rails.logger.error("Turnstile verification error: #{e.class} #{e.message}")
      { success: false, error: "verification_error" }
    end
  end
end
