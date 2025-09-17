# frozen_string_literal: true

module HoneybadgerRateLimiter
  HOURLY_LIMIT = 50
  DAILY_LIMIT = 500

  module_function

  def allow?(notice)
    fingerprint = notice.fingerprint || "#{notice.error_class}:#{notice.component}"

    hour_key = "hb_rate:#{fingerprint}:h:#{Time.current.beginning_of_hour.to_i}"
    day_key  = "hb_rate:#{fingerprint}:d:#{Date.current.beginning_of_day.to_i}"

    hour_count = Rails.cache.increment(hour_key)
    day_count = Rails.cache.increment(day_key)

    return false if hour_count > HOURLY_LIMIT || day_count > DAILY_LIMIT

    # go back and set expiration if this is the first time
    Rails.cache.write(hour_key, hour_count, expires_in: 1.hour) if hour_count == 1
    Rails.cache.write(day_key, day_count, expires_in: 1.day) if day_count == 1

    true
  rescue => e
    # If cache fails (e.g., Redis down), allow the error to be reported
    # to prevent circular dependency where Redis errors can't be reported
    true
  end
end
