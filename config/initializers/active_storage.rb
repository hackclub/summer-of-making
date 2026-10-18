Rails.application.configure do
  # The archive serves stored originals and does not decode or transform uploads.
  config.active_storage.variant_processor = :disabled
  config.active_storage.analyzers = []
  config.active_storage.previewers = []
  config.active_storage.variable_content_types = []

  # Set ActiveStorage analysis jobs to run on literally_whenever queue
  config.active_storage.queues.analysis = :literally_whenever
  config.active_storage.queues.purge = :literally_whenever
end
