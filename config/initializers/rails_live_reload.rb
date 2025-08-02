# frozen_string_literal: true

RailsLiveReload.configure do |config|
  # config.url = "/rails/live/reload"

  # Default watched folders & files
  # config.watch %r{app/views/.+\.(erb|haml|slim)$}
  # config.watch %r{(app|vendor)/(assets|javascript)/\w+/(.+\.(css|js|html|png|jpg|ts|jsx)).*}, reload: :always

  # More examples:
  # config.watch %r{app/helpers/.+\.rb}, reload: :always
  # config.watch %r{config/locales/.+\.yml}, reload: :always

  # Ignored folders & files
  # config.ignore %r{node_modules/}

  # Enable live reload unless explicitly disabled
  config.enabled = Rails.env.development? && !ENV["DISABLE_LIVE_RELOAD"]
end if defined?(RailsLiveReload)
