require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Journey
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    Rails.application.config.assets.paths << Rails.root.join("app", "assets", "videos")

    # Run jobs dashboard behind admin controller
    MissionControl::Jobs.base_controller_class = "Admin::ApplicationController"
    config.mission_control.jobs.http_basic_auth_enabled = false

    # W IN THE CHAT FOR RACK ATTACK I LOVE YOU
    config.middleware.use Rack::Attack

    # html minify
    # config.middleware.use HtmlCompressor::Rack

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("app/models/shop_item")
    # config.autoload_paths << Rails.root.join("app/models/shop_item")
    config.after_initialize { eager_load! }

    # bring in game constants from yaml
    config.game_constants = config_for(:game_constants)

    config.flipper_features = config_for(:flipper_features)

    # let sessions last a while >_<
    config.session_store :cookie_store,
                         key: "_journey_session",
                         expire_after: 30.days,
                         secure: Rails.env.production?,
                         httponly: true

    config.exceptions_app = self.routes
  end
end
