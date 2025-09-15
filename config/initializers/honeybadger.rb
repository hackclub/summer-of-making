# require "honeybadger_rate_limiter"

Honeybadger.configure do |config|
  config.api_key = Rails.application.credentials.honeybadger_auth

  # config.before_notify do |notice|
  #   throw :skip unless HoneybadgerRateLimiter.allow?(notice)
  # end
end
