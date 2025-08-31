Rails.application.configure do
  ## Memoization ensures that only one adapter call is made per feature per request.
  ## For more info, see https://www.flippercloud.io/docs/optimization#memoization
  # config.flipper.memoize = true

  ## Flipper preloads all features before each request, which is recommended if:
  ##   * you have a limited number of features (< 100?)
  ##   * most of your requests depend on most of your features
  ##   * you have limited gate data combined across all features (< 1k enabled gates, like individual actors, across all features)
  ##
  ## For more info, see https://www.flippercloud.io/docs/optimization#preloading
  # config.flipper.preload = true

  ## Warn or raise an error if an unknown feature is checked
  ## Can be set to `:warn`, `:raise`, or `false`
  # config.flipper.strict = Rails.env.development? && :warn

  ## Show Flipper checks in logs
  # config.flipper.log = true

  ## Reconfigure Flipper to use the Memory adapter and disable Cloud in tests
  # config.flipper.test_help = true

  ## The path that Flipper Cloud will use to sync features
  # config.flipper.cloud_path = "_flipper"

  ## The instrumenter that Flipper will use. Defaults to ActiveSupport::Notifications.
  # config.flipper.instrumenter = ActiveSupport::Notifications
end

Flipper.configure do |config|
  ## Configure other adapters that you want to use here:
  ## See http://flippercloud.io/docs/adapters
  # config.use Flipper::Adapters::ActiveSupportCacheStore, Rails.cache, expires_in: 5.minutes
end

## Register a group that can be used for enabling features.
##
##   Flipper.enable_group :my_feature, :admins
##
## See https://www.flippercloud.io/docs/features#enablement-group

Flipper.register(:admins) do |actor|
 actor.respond_to?(:is_admin?) && actor.is_admin?
end

Flipper::UI.configure do |config|
  if Rails.env.production?
    config.banner_text = "hey, you're in prod... be careful :3"
    config.banner_class = "warning"
  end

  config.actor_names_source = ->(actor_ids) do
    grouped_actors = actor_ids.each_with_object(Hash.new { |h, k| h[k] = [] }) do |actor_id, result|
      parts = actor_id.split(";")
      result[parts.first] << parts.second
    end
    actor_names = {}
    grouped_actors.each do |type, ids|
      model = type.constantize rescue nil
      next unless model
      model.where(id: ids).find_each do |actor|
        actor_names[actor.flipper_id] = actor.try(:display_name) || actor.try(:name) || actor.try(:title)
      end
    end
    actor_names.compact_blank
  end

  config.descriptions_source = ->(_keys) { Rails.configuration.flipper_features }
end
