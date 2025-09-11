# AhoyCaptain.configure do |config|
#   # ==> Event tracking
#   #
#   # View name
#   # The event you use to dictate if a page view occurred
#   # config.event.view_name = "$view"
#   #
#   # URL column
#   # The properties that indicate what URL was viewed. Ahoy suggested tracking the
#   # controller and action for each view by default, so we use that here.
#   # config.event.url_column = "CONCAT(properties->>'controller', '#', properties->>'action')"
#   #
#   # If you have a `url` key in your `properties`, you could:
#   # config.event.url_column = "properties->>'url'"
#   #
#   # URL exists
#   # A query that indicates if a view event has the correct properties for a page view.
#   # config.event.url_exists = "JSONB_EXISTS(properties, 'controller') AND JSONB_EXISTS(properties, 'action')"
#   #
#   # ==> Models
#   #
#   # Ahoy::Event model
#   # config.models.event = '::Ahoy::Event'
#   #
#   # Ahoy::Visit model
#   # config.models.visit = '::Ahoy::Visit'
#   #
#   #
#   # ==> Theme
#   #
#   # https://daisyui.com/docs/themes/
#   # config.theme = "dark"

#   # ==> Disabled widgets
#   # Some widgets are more expensive than others. You can disable them here.
#   #
#   # Here's the list of widgets:
#   #   * sources
#   #   * campaigns.utm_medium
#   #   * campaigns.utm_source
#   #   * campaigns.utm_term
#   #   * campaigns.utm_content
#   #   * campaigns.utm_campaign
#   #   * top_pages
#   #   * entry_pages
#   #   * landing_pages
#   #   * locations.countries
#   #   * locations.regions
#   #   * locations.cities
#   #   * devices.browsers
#   #   * devices.operating_systems
#   #   * devices.device_types
#   #
#   # config.disabled_widgets = []

#   # ==> Time periods
#   #
#   # Defaults come from lib/ahoy_captain/period_collection.rb
#   #
#   # If you want your own entirely, first call reset.
#   # config.ranges.reset
#   #
#   # Then you can add your own.
#   # config.ranges.add :param_name, "Label", -> { [3.days.ago, Date.today] }
#   #
#   # You can also remove an existing one:
#   # config.ranges.delete(:mtd)
#   #
#   # Or add to the defaults:
#   # config.ranges.add :custom, "Custom", -> { [6.hours.ago, 2.minutes.ago] }
#   #
#   # Or overwrite the defaults:
#   # config.ranges.add :mtd, "Custom MTD", -> { [2.weeks.ago, Time.current] }
#   #
#   # And handle the default range, which will be used if no range is given:
#   # config.ranges.default = '3d'
#   #
#   # The max range if a custom range is sent
#   # config.ranges.max = 180.days
#   #
#   # Set to false to disable custom ranges
#   # config.ranges.custom = true
#   #
#   # For an interval to be considered "realtime" it must not have a secondary item in the range

#   # ==> Filters
#   #
#   # Defaults come from lib/ahoy_captain/filter_configuration.rb
#   #
#   # If you want your own entirely, first call reset.
#   # config.filters.reset
#   #
#   # Then you can add your own.
#   #
#   # config.filters.register "Group label" do
#   #   filter label: "Some label", column: :column_name, url: :url_for_options, predicates: [:in, :not_in], multiple: true
#   # end
#   #
#   # You can also remove an existing group:
#   #
#   # config.filters.delete("Group label")
#   #
#   # Remove a specific filter from a group:
#   #
#   # config.filters["Group label"].delete(:column_name)
#   #
#   # You can add to an existing group:
#   #
#   # config.filters["Group label"].filter label: "Some label", column: :column_name, url: :url_for_options, predicates: [:in, :not_in], multiple: true

#   # ==> Caching
#   # config.cache.enabled = false
#   #
#   # Cache store should be an ActiveSupport::Cache::Store instance
#   # config.cache.store = Rails.cache
#   #
#   # TTL
#   # config.cache.ttl = 1.minute

#   #==> Goal tracking
#   # Your mother told you to have goals. Track those goals.
#   #
#   # Basically:
#   #
#   #   config.goal :unique_id do
#   #     label "Some label here"
#   #     name "The event name you're tracking in your Ahoy::Event table"
#   #   end
#   #
#   # Real-world example:
#   #
#   #   config.goal :appointment_paid do
#   #     label "Appointment Paid"
#   #     name "$appointment.paid"
#   #   end
#   #
#   # You can also use queries:
#   #
#   #   config.goal :appointment_paid do
#   #     label "Appointment Paid"
#   #     query do
#   #       ::Ahoy::Event.where(...)
#   #     end
#   #   end

#   # Tutorial Goals
#   config.goal :landing_visit do
#     label "Landing Page Visit"
#     name "tutorial_step_landing_first_visit"
#   end

#   config.goal :email_signup do
#     label "Email Signup"
#     name "tutorial_step_email_signup"
#   end

#   config.goal :slack_signin do
#     label "Slack Sign In"
#     name "tutorial_step_slack_signin"
#   end

#   config.goal :magic_link_signin do
#     label "Magic Link Sign In"
#     name "tutorial_step_magic_link_signin"
#   end

#   config.goal :hackatime_first_log do
#     label "Hackatime First Log"
#     name "tutorial_step_hackatime_first_log"
#   end

#   config.goal :identity_vault_linked do
#     label "Identity Vault Linked"
#     name "tutorial_step_identity_vault_linked"
#   end

#   config.goal :identity_vault_redirect do
#     label "Identity Vault Redirect"
#     name "tutorial_step_identity_vault_redirect"
#   end

#   config.goal :hackatime_redirect do
#     label "Hackatime Redirect"
#     name "tutorial_step_hackatime_redirect"
#   end

#   config.goal :first_project_created do
#     label "First Project Created"
#     name "tutorial_step_first_project_created"
#   end

#   config.goal :first_project_shipped do
#     label "First Project Shipped"
#     name "tutorial_step_first_project_shipped"
#   end

#   config.goal :free_stickers_ordered do
#     label "Free Stickers Ordered"
#     name "tutorial_step_free_stickers_ordered"
#   end

#   # ==> Funnels
#   # Your mother definitely didn't tell you about conversation rate.
#   # Except, you're here, so...
#   #
#   # Basically:
#   #
#   #   config.funnel :id do
#   #     label "Some label"
#   #     goal :goal_id_1
#   #     goal :goal_id_2
#   #   end
#   #
#   # Real-world example:
#   #
#   #   config.funnel :appointments do
#   #     label "Appointment Workflow"
#   #     goal :appointment_created
#   #     goal :appointment_paid
#   #   end

#   config.funnel :funnel_cake do
#     label "the ones that count"
#     goal :landing_visit
#     goal :email_signup
#     goal :slack_signin
#     goal :hackatime_first_log
#     goal :identity_vault_linked
#     goal :free_stickers_ordered
#     goal :first_project_created
#     goal :first_project_shipped
#   end

#   config.funnel :everything do
#     label "Every Single Tracked Event"
#     goal :landing_visit
#     goal :email_signup
#     goal :slack_signin
#     goal :magic_link_signin
#     goal :hackatime_redirect
#     goal :hackatime_first_log
#     goal :identity_vault_redirect
#     goal :identity_vault_linked
#     goal :free_stickers_ordered
#     goal :first_project_created
#     goal :first_project_shipped
#   end
#   #
#   # => Realtime interval
#   # config.realtime_interval = 30.seconds
#   #
#   # How frequently the page should refresh if the interval is realtime
# end
