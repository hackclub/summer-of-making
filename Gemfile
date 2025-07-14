# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

# Serverside analytics
gem "ahoy_matey"
gem "ahoy_captain", git: "https://github.com/johnmcdowall/ahoy_captain.git", branch: "fix_importmaps"
gem "geocoder"

# Dashboard for solidqueue
gem "mission_control-jobs"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Monitoring performance
gem "skylight"

# For call-stack profiling flamegraphs
gem "stackprof"
# Rack Mini Profiler [https://github.com/MiniProfiler/rack-mini-profiler]
gem "rack-mini-profiler", require: false
# For memory profiling via RMP
gem "memory_profiler"
gem "flamegraph"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # ERB linting [https://github.com/Shopify/erb_lint]
  gem "erb_lint", require: false

  gem "dotenv-rails"

  # Language Server Protocol for Ruby
  gem "ruby-lsp", require: false

  # Annotate Rails models
  gem "annotaterb", "~> 4.15"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Auto-reload pages after a code change
  gem "rails_live_reload"

  # For catching N+1 queries and unused eager loading [https://github.com/flyerhzm/bullet]
  gem "bullet"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem "tailwindcss-ruby"

gem "slack-ruby-client"

gem "inline_svg"

gem "airrecord"

# Pull airtable for airtable-backed models
gem "norairrecord"

# Honeybadger for team's error tracking
gem "honeybadger", "~> 5.28"

gem "redcarpet"

gem "pagy"

gem "chartkick", "~> 5.1"

gem "groupdate", "~> 6.6"

gem "ruby-openai", "~> 8.1"

gem "ferrum_pdf", "~> 0.3.0"

gem "streamio-ffmpeg", "~> 3.0"

gem "image_processing", "~> 1.14"

gem "avo", ">= 3.2"
gem "aws-sdk-s3", require: false

gem "lz_string", "~> 0.3.0"

gem "aasm", "~> 5.5"

gem "public_activity", "~> 3.0"

gem "blazer", "~> 3.3"

gem "pundit", "~> 2.5"

gem "awesome_print", "~> 1.9"

gem "flipper", "1.3.4"
gem "flipper-active_record", "1.3.4"
gem "flipper-ui", "1.3.4"

gem "mini_magick", "~> 5.2"

gem "redis", "~> 5.4"

gem "rack-attack", "~> 6.7"

gem "sanitize", "~> 7.0"
