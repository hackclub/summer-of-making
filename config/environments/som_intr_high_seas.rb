# frozen_string_literal: true

Rails.application.configure do
  # Use development settings as base
  config.load_defaults 8.0

  # Set eager_load to false for this environment
  config.eager_load = false

  # Use environment variable or generate a random secret for testing
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") {
    "som_intr_high_seas_test_secret_key_base_that_is_consistent_across_runs_and_only_used_for_integration_testing_not_production"
  }

  # Other development-like settings
  config.cache_classes = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Configure Active Storage

  # Store uploaded files on the local file system
  config.active_storage.service = :local

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests
  config.assets.quiet = true

  # Raises error for missing translations
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true
end
