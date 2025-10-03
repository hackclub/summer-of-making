# Configuration for Ship Certifications feature flags and constants
# Payout system launch timestamp, used to compute reviewer payment stats.
# Configure via ENV['SHIP_CERTIFICATIONS_PAYOUT_LAUNCH_AT'] (in app time zone),
# defaulting to 2025-09-03 00:00:00.
Rails.application.config.x.ship_certifications_payout_launch_at = begin
  raw = ENV.fetch("SHIP_CERTIFICATIONS_PAYOUT_LAUNCH_AT", "2025-09-03 00:00:00")
  # Parse in the app's configured time zone for consistency across environments
  Time.zone.parse(raw)
rescue ArgumentError, TypeError
  Time.zone.local(2025, 9, 3, 0, 0, 0)
end

# Recertification deadline configuration
# After this deadline, users get only one additional recertification attempt before being blocked
# Configure via ENV['RECERTIFICATION_DEADLINE'] (in app time zone),
# defaulting to 2025-10-02 23:59:59 EST
Rails.application.config.x.recertification_deadline = begin
  raw = ENV.fetch("RECERTIFICATION_DEADLINE", "2025-10-02 23:59:59")
  # Parse in the app's configured time zone for consistency across environments
  Time.zone.parse(raw)
rescue ArgumentError, TypeError
  Time.zone.local(2025, 10, 2, 23, 59, 59)
end
