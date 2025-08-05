# Be sure to restart your server when you modify this file.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from secure origins for prod, localhost for dev
    origins lambda { |origin, _env|
      origin =~ %r{\Ahttp://localhost:\d+\z} ||
      origin =~ %r{\Ahttps://.*\z}
    }
    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
