# == Route Map
#
#                                   Prefix Verb   URI Pattern                                                                                       Controller#Action
#                                                 /assets                                                                                           Propshaft::Server
#                                      avo        /avo                                                                                              Avo::Engine
#                       rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                                     root GET    /                                                                                                 landing#index
#                                  sign_up POST   /sign-up(.:format)                                                                                landing#sign_up
#                               auth_slack GET    /auth/slack(.:format)                                                                             sessions#new
#                           slack_callback GET    /auth/slack/callback(.:format)                                                                    sessions#create
#                             auth_failure GET    /auth/failure(.:format)                                                                           sessions#failure
#                                   logout DELETE /logout(.:format)                                                                                 sessions#destroy
#                               magic_link GET    /magic-link(.:format)                                                                             sessions#magic_link
#                  identity_vault_callback GET    /users/identity_vault_callback(.:format)                                                          users#identity_vault_callback
#                      link_identity_vault GET    /users/link_identity_vault(.:format)                                                              users#link_identity_vault
#                                  explore GET    /explore(.:format)                                                                                projects#index
#                                  gallery GET    /gallery(.:format)                                                                                projects#gallery
#                              my_projects GET    /my_projects(.:format)                                                                            projects#my_projects
#                               check_link POST   /check_link(.:format)                                                                             projects#check_link
#                    timer_sessions_active GET    /timer_sessions/active(.:format)                                                                  timer_sessions#global_active
#                          project_devlogs POST   /projects/:project_id/devlogs(.:format)                                                           devlogs#create
#                           project_devlog PATCH  /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#update
#                                          PUT    /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#update
#                                          DELETE /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#destroy
#            active_project_timer_sessions GET    /projects/:project_id/timer_sessions/active(.:format)                                             timer_sessions#active
#                   project_timer_sessions POST   /projects/:project_id/timer_sessions(.:format)                                                    timer_sessions#create
#                    project_timer_session GET    /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#show
#                                          PATCH  /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#update
#                                          PUT    /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#update
#                                          DELETE /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#destroy
#                           follow_project POST   /projects/:id/follow(.:format)                                                                    projects#follow
#                         unfollow_project DELETE /projects/:id/unfollow(.:format)                                                                  projects#unfollow
#                             ship_project PATCH  /projects/:id/ship(.:format)                                                                      projects#ship
#                     stake_stonks_project POST   /projects/:id/stake_stonks(.:format)                                                              projects#stake_stonks
#                   unstake_stonks_project DELETE /projects/:id/unstake_stonks(.:format)                                                            projects#unstake_stonks
#                                 projects GET    /projects(.:format)                                                                               projects#index
#                                          POST   /projects(.:format)                                                                               projects#create
#                              new_project GET    /projects/new(.:format)                                                                           projects#new
#                             edit_project GET    /projects/:id/edit(.:format)                                                                      projects#edit
#                                  project GET    /projects/:id(.:format)                                                                           projects#show
#                                          PATCH  /projects/:id(.:format)                                                                           projects#update
#                                          PUT    /projects/:id(.:format)                                                                           projects#update
#                                          DELETE /projects/:id(.:format)                                                                           projects#destroy
#                                  devlogs GET    /devlogs(.:format)                                                                                devlogs#index
#                                    votes POST   /votes(.:format)                                                                                  votes#create
#                                 new_vote GET    /votes/new(.:format)                                                                              votes#new
#                               shop_item POST   /shop_item(.:format)                                                                             shop_item#create
#                            new_shop_item GET    /shop_item/new(.:format)                                                                         shop_item#new
#                           edit_shop_item GET    /shop_item/:id/edit(.:format)                                                                    shop_item#edit
#                                shop_item GET    /shop_item/:id(.:format)                                                                         shop_item#show
#                                          PATCH  /shop_item/:id(.:format)                                                                         shop_item#update
#                                          PUT    /shop_item/:id(.:format)                                                                         shop_item#update
#                                          DELETE /shop_item/:id(.:format)                                                                         shop_item#destroy
#                                     shop GET    /shop(.:format)                                                                                   shop_item#index
#                                                 /404(.:format)                                                                                    errors#not_found
#                                                 /500(.:format)                                                                                    errors#internal_server_error
#                                                 /422(.:format)                                                                                    errors#unprocessable_entity
#                                                 /400(.:format)                                                                                    errors#bad_request
#                       upload_attachments POST   /attachments/upload(.:format)                                                                     attachments#upload
#                     download_attachments GET    /attachments/download(.:format)                                                                   attachments#download
#                          devlog_comments POST   /devlogs/:devlog_id/comments(.:format)                                                            comments#create
#                           devlog_comment DELETE /devlogs/:devlog_id/comments/:id(.:format)                                                        comments#destroy
#                       toggle_like_devlog POST   /devlogs/:id/toggle_like(.:format)                                                                likes#toggle
#                                          GET    /devlogs(.:format)                                                                                devlogs#index
#                                          POST   /devlogs(.:format)                                                                                devlogs#create
#                               new_devlog GET    /devlogs/new(.:format)                                                                            devlogs#new
#                              edit_devlog GET    /devlogs/:id/edit(.:format)                                                                       devlogs#edit
#                                   devlog GET    /devlogs/:id(.:format)                                                                            devlogs#show
#                                          PATCH  /devlogs/:id(.:format)                                                                            devlogs#update
#                                          PUT    /devlogs/:id(.:format)                                                                            devlogs#update
#                                          DELETE /devlogs/:id(.:format)                                                                            devlogs#destroy
#                   tutorial_complete_step POST   /tutorial/complete_step(.:format)                                                                 tutorial_progress#complete_step
#                          api_v1_projects GET    /api/v1/projects(.:format)                                                                        api/v1/projects#index
#                           api_v1_project GET    /api/v1/projects/:id(.:format)                                                                    api/v1/projects#show
#                           api_v1_devlogs GET    /api/v1/devlogs(.:format)                                                                         api/v1/devlogs#index
#                            api_v1_devlog GET    /api/v1/devlogs/:id(.:format)                                                                     api/v1/devlogs#show
#                          api_v1_comments GET    /api/v1/comments(.:format)                                                                        api/v1/comments#index
#                           api_v1_comment GET    /api/v1/comments/:id(.:format)                                                                    api/v1/comments#show
#                             api_v1_emote GET    /api/v1/emotes/:id(.:format)                                                                      api/v1/emotes#show
#                           api_check_user GET    /api/check_user(.:format)                                                                         users#check_user
#                              api_devlogs POST   /api/devlogs(.:format)                                                                            devlogs#api_create
#      users_update_hackatime_confirmation POST   /users/update_hackatime_confirmation(.:format)                                                    users#update_hackatime_confirmation
#                  users_refresh_hackatime POST   /users/refresh_hackatime(.:format)                                                                users#refresh_hackatime
#         users_check_hackatime_connection POST   /users/check_hackatime_connection(.:format)                                                       users#check_hackatime_connection
#         turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#         turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
#        turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#            rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#               rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#            rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#      rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#            rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#             rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#           rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                          POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#        new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#            rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
# new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#    rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#    rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
# rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                       rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                 rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                          GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#          rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                          GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                       rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                     rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for Avo::Engine:
#                                root GET    /                                                                                                  avo/home#index
#              avo_resources_redirect GET    /resources(.:format)                                                                               redirect(301, /avo)
#             avo_dashboards_redirect GET    /dashboards(.:format)                                                                              redirect(301, /avo)
#                 media_library_index GET    /media-library(.:format)                                                                           avo/media_library#index
#                       media_library GET    /media-library/:id(.:format)                                                                       avo/media_library#show
#                                     PATCH  /media-library/:id(.:format)                                                                       avo/media_library#update
#                                     PUT    /media-library/:id(.:format)                                                                       avo/media_library#update
#                                     DELETE /media-library/:id(.:format)                                                                       avo/media_library#destroy
#                        attach_media GET    /attach-media(.:format)                                                                            avo/media_library#attach
# rails_active_storage_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                     active_storage/direct_uploads#create
#                      avo_api_search GET    /avo_api/search(.:format)                                                                          avo/search#index
#                             avo_api GET    /avo_api/:resource_name/search(.:format)                                                           avo/search#show
#                                     POST   /avo_api/resources/:resource_name/:id/attachments(.:format)                                        avo/attachments#create
#                  distribution_chart GET    /:resource_name/:field_id/distribution_chart(.:format)                                             avo/charts#distribution_chart
#                      failed_to_load GET    /failed_to_load(.:format)                                                                          avo/home#failed_to_load
#                           resources DELETE /resources/:resource_name/:id/active_storage_attachments/:attachment_name/:attachment_id(.:format) avo/attachments#destroy
#                                     GET    /resources/:resource_name(/:id)/actions(/:action_id)(.:format)                                     avo/actions#show
#                                     POST   /resources/:resource_name(/:id)/actions(/:action_id)(.:format)                                     avo/actions#handle
#              preview_resources_user GET    /resources/users/:id/preview(.:format)                                                             avo/users#preview
#                     resources_users GET    /resources/users(.:format)                                                                         avo/users#index
#                                     POST   /resources/users(.:format)                                                                         avo/users#create
#                  new_resources_user GET    /resources/users/new(.:format)                                                                     avo/users#new
#                 edit_resources_user GET    /resources/users/:id/edit(.:format)                                                                avo/users#edit
#                      resources_user GET    /resources/users/:id(.:format)                                                                     avo/users#show
#                                     PATCH  /resources/users/:id(.:format)                                                                     avo/users#update
#                                     PUT    /resources/users/:id(.:format)                                                                     avo/users#update
#                                     DELETE /resources/users/:id(.:format)                                                                     avo/users#destroy
#         preview_resources_shop_item GET    /resources/shop_item/:id/preview(.:format)                                                        avo/shop_item#preview
#                resources_shop_items GET    /resources/shop_item(.:format)                                                                    avo/shop_item#index
#                                     POST   /resources/shop_item(.:format)                                                                    avo/shop_item#create
#             new_resources_shop_item GET    /resources/shop_item/new(.:format)                                                                avo/shop_item#new
#            edit_resources_shop_item GET    /resources/shop_item/:id/edit(.:format)                                                           avo/shop_item#edit
#                 resources_shop_item GET    /resources/shop_item/:id(.:format)                                                                avo/shop_item#show
#                                     PATCH  /resources/shop_item/:id(.:format)                                                                avo/shop_item#update
#                                     PUT    /resources/shop_item/:id(.:format)                                                                avo/shop_item#update
#                                     DELETE /resources/shop_item/:id(.:format)                                                                avo/shop_item#destroy
#        preview_resources_magic_link GET    /resources/magic_links/:id/preview(.:format)                                                       avo/magic_links#preview
#               resources_magic_links GET    /resources/magic_links(.:format)                                                                   avo/magic_links#index
#                                     POST   /resources/magic_links(.:format)                                                                   avo/magic_links#create
#            new_resources_magic_link GET    /resources/magic_links/new(.:format)                                                               avo/magic_links#new
#           edit_resources_magic_link GET    /resources/magic_links/:id/edit(.:format)                                                          avo/magic_links#edit
#                resources_magic_link GET    /resources/magic_links/:id(.:format)                                                               avo/magic_links#show
#                                     PATCH  /resources/magic_links/:id(.:format)                                                               avo/magic_links#update
#                                     PUT    /resources/magic_links/:id(.:format)                                                               avo/magic_links#update
#                                     DELETE /resources/magic_links/:id(.:format)                                                               avo/magic_links#destroy
#          resources_associations_new GET    /resources/:resource_name/:id/:related_name/new(.:format)                                          avo/associations#new
#        resources_associations_index GET    /resources/:resource_name/:id/:related_name(.:format)                                              avo/associations#index
#         resources_associations_show GET    /resources/:resource_name/:id/:related_name/:related_id(.:format)                                  avo/associations#show
#       resources_associations_create POST   /resources/:resource_name/:id/:related_name(.:format)                                              avo/associations#create
#      resources_associations_destroy DELETE /resources/:resource_name/:id/:related_name/:related_id(.:format)                                  avo/associations#destroy
#                  avo_private_status GET    /avo_private/status(.:format)                                                                      avo/debug#status
#              avo_private_send_to_hq POST   /avo_private/status/send_to_hq(.:format)                                                           avo/debug#send_to_hq
#            avo_private_debug_report GET    /avo_private/debug/report(.:format)                                                                avo/debug#report
#   avo_private_debug_refresh_license POST   /avo_private/debug/refresh_license(.:format)                                                       avo/debug#refresh_license
#                  avo_private_design GET    /avo_private/design(.:format)                                                                      avo/private#design

class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.is_admin?
  end
end

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path is landing page for unauthenticated, redirects to dashboard for authenticated
  root "landing#index"
  post "/sign-up", to: "landing#sign_up"

  # Authentication routes
  get "/auth/slack", to: "sessions#new"
  get "/auth/slack/callback", to: "sessions#create", as: :slack_callback
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/magic-link", to: "sessions#magic_link", as: :magic_link # For users signing in
  post "/explorpheus/magic-link", to: "magic_link#get_secret_magic_url" # For the welcome bot to fetch the magic link.

  # Identity Vault routes
  get "users/identity_vault_callback", to: "users#identity_vault_callback", as: :identity_vault_callback
  get "users/link_identity_vault", to: "users#link_identity_vault", as: :link_identity_vault

  get "users/hackatime_auth_redirect", to: "users#hackatime_auth_redirect", as: :hackatime_auth_redirect

  # Dashboard
  # get "dashboard", to: "dashboard#index"

  get "explore", to: "projects#index"
  get "my_projects", to: "projects#my_projects"
  post "check_link", to: "projects#check_link"
  get "check_github_readme", to: "projects#check_github_readme"
  get "campfire", to: "campfire#index"
  get "campfire/hackatime_status", to: "campfire#hackatime_status"

  # Global timer session check - must be before projects resource
  get "timer_sessions/active", to: "timer_sessions#global_active"

  resources :projects do
    resources :devlogs, only: [ :create, :destroy, :update ]
    resources :timer_sessions, only: [ :create, :update, :show, :destroy ] do
      collection do
        get :active
      end
    end
    member do
      post :follow
      delete :unfollow
      patch :ship
      post :stake_stonks
      delete :unstake_stonks
      # patch :recover
    end
  end

  get "devlogs", to: "devlogs#index"
  resources :votes, only: [ :new, :create ] do
    get :locked, on: :collection
  end

  scope :shop do
    get "/", to: "shop_items#index", as: :shop
    resources :shop_items, except: [ :index ], path: :items do
      member do
        get :buy, to: "shop_orders#new", as: :order
        post :buy, to: "shop_orders#create", as: :checkout
      end
    end
    resources :shop_orders, path: :orders, except: %i[edit update new]
  end

  # Payouts etc
  get "/payouts/:slack_id", to: "payouts#index"

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/400", to: "errors#bad_request", via: :all

  resources :attachments, only: [] do
    collection do
      post :upload
      get :download
    end
  end

  resources :devlogs do
    resources :comments, only: [ :create, :destroy ]
    member do
      post :toggle_like, to: "likes#toggle"
    end
  end

  post "tutorial/complete_step", to: "tutorial_progress#complete_step"
  post "tutorial/complete_soft_tutorial_step", to: "tutorial_progress#complete_soft_step", as: :complete_soft_tutorial_step

  get "/payouts", to: "payouts#index"

  # API routes
  namespace :api do
    namespace :v1 do
      resources :projects, only: [ :index, :show ]
      resources :devlogs, only: [ :index, :show ]
      resources :comments, only: [ :index, :show ]
      resources :emotes, only: [ :show ]
    end
  end
  get "api/check_user", to: "users#check_user"
  post "api/devlogs", to: "devlogs#api_create"

  # User Hackatime routes
  post "users/update_hackatime_confirmation", to: "users#update_hackatime_confirmation"
  post "users/refresh_hackatime", to: "users#refresh_hackatime"
  post "users/check_hackatime_connection", to: "users#check_hackatime_connection"

  resources :ship_event_feedbacks

  namespace :admin, constraint: AdminConstraint do
    mount MissionControl::Jobs::Engine, at: "jobs"
    mount AhoyCaptain::Engine, at: "ahoy_captain"
    mount Blazer::Engine, at: "blazer"
    mount Flipper::UI.app(Flipper), at: "flipper", as: :flipper
    # mount_avo
    get "/", to: "static_pages#index", as: :root
    resources :ship_certifications, only: [ :index, :show, :edit, :update ]
    resources :users, only: [ :index, :show ] do
      member do
        post :internal_notes
        post :create_payout
        post :nuke_idv_data
        post :cancel_card_grants
        post :freeze
        post :defrost
      end
    end
    resources :shop_items
    resources :shop_orders do
      collection do
        get :pending
        get :awaiting_fulfillment
      end
      member do
        post :internal_notes
        post :approve
        post :reject
        post :place_on_hold
        post :take_off_hold
        post :mark_fulfilled
      end
    end
    resources :shop_card_grants, only: [ :index, :show ]
  end
end
