# frozen_string_literal: true

Rails.application.config.after_initialize do
  if defined?(Rails::Server) && Rails.env.production?
    HackatimeStatRefreshJob.perform_later
  end
end
