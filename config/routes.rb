# == Route Map
#
#                                                    Prefix Verb   URI Pattern                                                                                       Controller#Action
#                                                  showcase GET    /showcase(.:format)                                                                               showcase#new
#                                                           POST   /showcase(.:format)                                                                               showcase#create
#                                           active_insights        /insights                                                                                         ActiveInsights::Engine
#                                        rails_health_check GET    /up(.:format)                                                                                     rails/health#show
#                                                      root GET    /                                                                                                 landing#index
#                                                   sign_up POST   /sign-up(.:format)                                                                                landing#sign_up
#                                       mailing_list_signup POST   /mailing-list-signup(.:format)                                                                    landing#mailing_list_signup
#                                                auth_slack GET    /auth/slack(.:format)                                                                             sessions#new
#                                            slack_callback GET    /auth/slack/callback(.:format)                                                                    sessions#create
#                                              auth_failure GET    /auth/failure(.:format)                                                                           sessions#failure
#                                                    logout DELETE /logout(.:format)                                                                                 sessions#destroy
#                                        stop_impersonating DELETE /stop_impersonating(.:format)                                                                     sessions#stop_impersonating
#                                            dev_auto_login GET    /auth/dev_login(.:format)                                                                         sessions#auto_login_dev
#                                                magic_link GET    /magic-link(.:format)                                                                             sessions#magic_link
#                                    explorpheus_magic_link POST   /explorpheus/magic-link(.:format)                                                                 magic_link#get_secret_magic_url
#                                   identity_vault_callback GET    /users/identity_vault_callback(.:format)                                                          users#identity_vault_callback
#                                       link_identity_vault GET    /users/link_identity_vault(.:format)                                                              users#link_identity_vault
#                                       tutorial_todo_modal GET    /tutorial/todo_modal(.:format)                                                                    tutorials#todo_modal
#                                   hackatime_auth_redirect GET    /users/hackatime_auth_redirect(.:format)                                                          users#hackatime_auth_redirect
#                                                   explore GET    /explore(.:format)                                                                                explore#index
#                                         explore_following GET    /explore/following(.:format)                                                                      explore#following
#                                           explore_gallery GET    /explore/gallery(.:format)                                                                        explore#gallery
#                                               my_projects GET    /my_projects(.:format)                                                                            projects#my_projects
#                                                check_link POST   /check_link(.:format)                                                                             projects#check_link
#                                       check_github_readme GET    /check_github_readme(.:format)                                                                    projects#check_github_readme
#                                                   wrapped GET    /wrapped(.:format)                                                                                wrapped#show
#                                            shared_wrapped GET    /wrapped/share/:share_token(.:format)                                                             wrapped#share
#                                                  campfire GET    /campfire(.:format)                                                                               campfire#index
#                                 campfire_hackatime_status GET    /campfire/hackatime_status(.:format)                                                              campfire#hackatime_status
#                                                       map GET    /map(.:format)                                                                                    map#index
#                                     timer_sessions_active GET    /timer_sessions/active(.:format)                                                                  timer_sessions#global_active
#                                           project_devlogs POST   /projects/:project_id/devlogs(.:format)                                                           devlogs#create
#                                            project_devlog PATCH  /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#update
#                                                           PUT    /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#update
#                                                           DELETE /projects/:project_id/devlogs/:id(.:format)                                                       devlogs#destroy
#                             active_project_timer_sessions GET    /projects/:project_id/timer_sessions/active(.:format)                                             timer_sessions#active
#                                    project_timer_sessions POST   /projects/:project_id/timer_sessions(.:format)                                                    timer_sessions#create
#                                     project_timer_session GET    /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#show
#                                                           PATCH  /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#update
#                                                           PUT    /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#update
#                                                           DELETE /projects/:project_id/timer_sessions/:id(.:format)                                                timer_sessions#destroy
#                                            project_follow POST   /projects/:project_id/follow(.:format)                                                            projects/follows#create
#                                          project_unfollow DELETE /projects/:project_id/unfollow(.:format)                                                          projects/follows#destroy
#                                            project_readme GET    /projects/:project_id/readme(.:format)                                                            projects/readmes#show
#                                   project_recertification POST   /projects/:project_id/recertification(.:format)                                                   projects/recertifications#create
#                                              project_ship POST   /projects/:project_id/ship(.:format)                                                              projects/ships#create
#                                      stake_stonks_project POST   /projects/:id/stake_stonks(.:format)                                                              projects#stake_stonks
#                                    unstake_stonks_project DELETE /projects/:id/unstake_stonks(.:format)                                                            projects#unstake_stonks
#                                update_coordinates_project PATCH  /projects/:id/update_coordinates(.:format)                                                        projects#update_coordinates
#                               unplace_coordinates_project DELETE /projects/:id/unplace_coordinates(.:format)                                                       projects#unplace_coordinates
#                                            devlog_project GET    /projects/:id/devlog/:devlog_id(.:format)                                                         projects#show
#                                                  projects GET    /projects(.:format)                                                                               projects#index
#                                                           POST   /projects(.:format)                                                                               projects#create
#                                               new_project GET    /projects/new(.:format)                                                                           projects#new
#                                              edit_project GET    /projects/:id/edit(.:format)                                                                      projects#edit
#                                                   project GET    /projects/:id(.:format)                                                                           projects#show
#                                                           PATCH  /projects/:id(.:format)                                                                           projects#update
#                                                           PUT    /projects/:id(.:format)                                                                           projects#update
#                                                           DELETE /projects/:id(.:format)                                                                           projects#destroy
#                                              locked_votes GET    /votes/locked(.:format)                                                                           votes#locked
#                                          track_demo_votes POST   /votes/track_demo/:position(.:format)                                                             votes#track_demo
#                                          track_repo_votes POST   /votes/track_repo/:position(.:format)                                                             votes#track_repo
#                                                     votes POST   /votes(.:format)                                                                                  votes#create
#                                                  new_vote GET    /votes/new(.:format)                                                                              votes#new
#                                             fraud_reports POST   /fraud_reports(.:format)                                                                          fraud_reports#create
#                                                      shop GET    /shop(.:format)                                                                                   shop_items#index
#                                              black_market GET    /shop/black_market(.:format)                                                                      shop_items#black_market
#                                           order_shop_item GET    /shop/items/:id/buy(.:format)                                                                     shop_orders#new
#                                        checkout_shop_item POST   /shop/items/:id/buy(.:format)                                                                     shop_orders#create
#                                                shop_items POST   /shop/items(.:format)                                                                             shop_items#create
#                                             new_shop_item GET    /shop/items/new(.:format)                                                                         shop_items#new
#                                            edit_shop_item GET    /shop/items/:id/edit(.:format)                                                                    shop_items#edit
#                                                 shop_item GET    /shop/items/:id(.:format)                                                                         shop_items#show
#                                                           PATCH  /shop/items/:id(.:format)                                                                         shop_items#update
#                                                           PUT    /shop/items/:id(.:format)                                                                         shop_items#update
#                                                           DELETE /shop/items/:id(.:format)                                                                         shop_items#destroy
#                                               shop_orders GET    /shop/orders(.:format)                                                                            shop_orders#index
#                                                           POST   /shop/orders(.:format)                                                                            shop_orders#create
#                                           edit_shop_order GET    /shop/orders/:id/edit(.:format)                                                                   shop_orders#edit
#                                                shop_order GET    /shop/orders/:id(.:format)                                                                        shop_orders#show
#                                                           PATCH  /shop/orders/:id(.:format)                                                                        shop_orders#update
#                                                           PUT    /shop/orders/:id(.:format)                                                                        shop_orders#update
#                                                           DELETE /shop/orders/:id(.:format)                                                                        shop_orders#destroy
#                                         edit_user_profile GET    /users/:user_id/profile/edit(.:format)                                                            user/profiles#edit
#                                              user_profile PATCH  /users/:user_id/profile(.:format)                                                                 user/profiles#update
#                                                           PUT    /users/:user_id/profile(.:format)                                                                 user/profiles#update
#                                                      user GET    /users/:id(.:format)                                                                              users#show
#                                                           GET    /payouts/:slack_id(.:format)                                                                      payouts#index
#                                                           GET    /404(.:format)                                                                                    errors#not_found
#                                                           GET    /500(.:format)                                                                                    errors#internal_server
#                                        upload_attachments POST   /attachments/upload(.:format)                                                                     attachments#upload
#                                      download_attachments GET    /attachments/download(.:format)                                                                   attachments#download
#                                           devlog_comments POST   /devlogs/:devlog_id/comments(.:format)                                                            comments#create
#                                            devlog_comment DELETE /devlogs/:devlog_id/comments/:id(.:format)                                                        comments#destroy
#                                        toggle_like_devlog POST   /devlogs/:id/toggle_like(.:format)                                                                likes#toggle
#                                                   devlogs GET    /devlogs(.:format)                                                                                devlogs#index
#                                                           POST   /devlogs(.:format)                                                                                devlogs#create
#                                                new_devlog GET    /devlogs/new(.:format)                                                                            devlogs#new
#                                               edit_devlog GET    /devlogs/:id/edit(.:format)                                                                       devlogs#edit
#                                                    devlog GET    /devlogs/:id(.:format)                                                                            devlogs#show
#                                                           PATCH  /devlogs/:id(.:format)                                                                            devlogs#update
#                                                           PUT    /devlogs/:id(.:format)                                                                            devlogs#update
#                                                           DELETE /devlogs/:id(.:format)                                                                            devlogs#destroy
#                                    tutorial_complete_step POST   /tutorial/complete_step(.:format)                                                                 tutorial_progress#complete_step
#                               complete_soft_tutorial_step POST   /tutorial/complete_soft_tutorial_step(.:format)                                                   tutorial_progress#complete_soft_step
#                                complete_new_tutorial_step POST   /tutorial/complete_new_tutorial_step(.:format)                                                    tutorial_progress#complete_new_step
#                                                   payouts GET    /payouts(.:format)                                                                                payouts#index
#                             ship_reviewer_payout_requests GET    /ship_reviewer_payout_requests(.:format)                                                          ship_reviewer_payout_requests#index
#                                                           POST   /ship_reviewer_payout_requests(.:format)                                                          ship_reviewer_payout_requests#create
#                                           api_v1_users_me GET    /api/v1/users/me(.:format)                                                                        api/v1/users#me
#                                   shipped_api_v1_projects GET    /api/v1/projects/shipped(.:format)                                                                api/v1/projects#shipped
#                                           api_v1_projects GET    /api/v1/projects(.:format)                                                                        api/v1/projects#index
#                                            api_v1_project GET    /api/v1/projects/:id(.:format)                                                                    api/v1/projects#show
#                                              api_v1_users GET    /api/v1/users(.:format)                                                                           api/v1/users#index
#                                               api_v1_user GET    /api/v1/users/:id(.:format)                                                                       api/v1/users#show
#                                            api_v1_devlogs GET    /api/v1/devlogs(.:format)                                                                         api/v1/devlogs#index
#                                             api_v1_devlog GET    /api/v1/devlogs/:id(.:format)                                                                     api/v1/devlogs#show
#                                           api_v1_comments GET    /api/v1/comments(.:format)                                                                        api/v1/comments#index
#                                            api_v1_comment GET    /api/v1/comments/:id(.:format)                                                                    api/v1/comments#show
#                                              api_v1_emote GET    /api/v1/emotes/:id(.:format)                                                                      api/v1/emotes#show
#                                    search_api_v2_projects GET    /api/v2/projects/search(.:format)                                                                 api/v2/projects#search
#                                           api_v2_projects GET    /api/v2/projects(.:format)                                                                        api/v2/projects#index
#                                            api_v2_project GET    /api/v2/projects/:id(.:format)                                                                    api/v2/projects#show
#                                       search_api_v2_users GET    /api/v2/users/search(.:format)                                                                    api/v2/users#search
#                                              api_v2_users GET    /api/v2/users(.:format)                                                                           api/v2/users#index
#                                               api_v2_user GET    /api/v2/users/:id(.:format)                                                                       api/v2/users#show
#                                            api_v2_devlogs GET    /api/v2/devlogs(.:format)                                                                         api/v2/devlogs#index
#                                             api_v2_devlog GET    /api/v2/devlogs/:id(.:format)                                                                     api/v2/devlogs#show
#                                            api_v2_payouts GET    /api/v2/payouts(.:format)                                                                         api/v2/payouts#index
#                                             api_v2_payout GET    /api/v2/payouts/:id(.:format)                                                                     api/v2/payouts#show
#                                                    api_v2 GET    /api/v2(.:format)                                                                                 api/v2/base#index
#                                            api_check_user GET    /api/check_user(.:format)                                                                         users#check_user
#                                               api_devlogs POST   /api/devlogs(.:format)                                                                            devlogs#api_create
#                                      ship_event_feedbacks GET    /ship_event_feedbacks(.:format)                                                                   ship_event_feedbacks#index
#                                                           POST   /ship_event_feedbacks(.:format)                                                                   ship_event_feedbacks#create
#                                   new_ship_event_feedback GET    /ship_event_feedbacks/new(.:format)                                                               ship_event_feedbacks#new
#                                  edit_ship_event_feedback GET    /ship_event_feedbacks/:id/edit(.:format)                                                          ship_event_feedbacks#edit
#                                       ship_event_feedback GET    /ship_event_feedbacks/:id(.:format)                                                               ship_event_feedbacks#show
#                                                           PATCH  /ship_event_feedbacks/:id(.:format)                                                               ship_event_feedbacks#update
#                                                           PUT    /ship_event_feedbacks/:id(.:format)                                                               ship_event_feedbacks#update
#                                                           DELETE /ship_event_feedbacks/:id(.:format)                                                               ship_event_feedbacks#destroy
#                                                track_view POST   /track_view(.:format)                                                                             view_tracking#create
#                                                      gork GET    /gork(.:format)                                                                                   static_pages#gork
#                                                       stt GET    /s(.:format)                                                                                      static_pages#s
#                            logs_admin_ship_certifications GET    /admin/ship_certifications/logs(.:format)                                                         admin/ship_certifications#logs
#                                 admin_ship_certifications GET    /admin/ship_certifications(.:format)                                                              admin/ship_certifications#index
#                             edit_admin_ship_certification GET    /admin/ship_certifications/:id/edit(.:format)                                                     admin/ship_certifications#edit
#                                  admin_ship_certification PATCH  /admin/ship_certifications/:id(.:format)                                                          admin/ship_certifications#update
#                                                           PUT    /admin/ship_certifications/:id(.:format)                                                          admin/ship_certifications#update
#        mark_low_quality_admin_low_quality_dashboard_index POST   /admin/low_quality_dashboard/mark_low_quality(.:format)                                           admin/low_quality_dashboard#mark_low_quality
#                 mark_ok_admin_low_quality_dashboard_index POST   /admin/low_quality_dashboard/mark_ok(.:format)                                                    admin/low_quality_dashboard#mark_ok
# message_repeat_offender_admin_low_quality_dashboard_index POST   /admin/low_quality_dashboard/message_repeat_offender(.:format)                                    admin/low_quality_dashboard#message_repeat_offender
#                         admin_low_quality_dashboard_index GET    /admin/low_quality_dashboard(.:format)                                                            admin/low_quality_dashboard#index
#                          block_recertification_admin_user POST   /admin/users/:id/block_recertification(.:format)                                                  admin/users#block_recertification
#                        unblock_recertification_admin_user POST   /admin/users/:id/unblock_recertification(.:format)                                                admin/users#unblock_recertification
#                                                admin_user GET    /admin/users/:id(.:format)                                                                        admin/users#show
#                                                admin_root GET    /admin(.:format)                                                                                  admin/static_pages#index
#                                resolve_admin_fraud_report GET    /admin/fraud_reports/:id/resolve(.:format)                                                        admin/fraud_reports#resolve
#                              unresolve_admin_fraud_report GET    /admin/fraud_reports/:id/unresolve(.:format)                                                      admin/fraud_reports#unresolve
#                                                           PATCH  /admin/fraud_reports/:id/resolve(.:format)                                                        admin/fraud_reports#resolve
#                                                           PATCH  /admin/fraud_reports/:id/unresolve(.:format)                                                      admin/fraud_reports#unresolve
#                                       admin_fraud_reports GET    /admin/fraud_reports(.:format)                                                                    admin/fraud_reports#index
#                                        admin_fraud_report GET    /admin/fraud_reports/:id(.:format)                                                                admin/fraud_reports#show
#        send_letter_mail_admin_fulfillment_dashboard_index POST   /admin/fulfillment_dashboard/send_letter_mail(.:format)                                           admin/fulfillment_dashboard#send_letter_mail
#                         admin_fulfillment_dashboard_index GET    /admin/fulfillment_dashboard(.:format)                                                            admin/fulfillment_dashboard#index
#                              admin_voting_dashboard_index GET    /admin/voting_dashboard(.:format)                                                                 admin/voting_dashboard#index
#                             admin_payouts_dashboard_index GET    /admin/payouts_dashboard(.:format)                                                                admin/payouts_dashboard#index
#                                 pending_admin_shop_orders GET    /admin/shop_orders/pending(.:format)                                                              admin/shop_orders#pending
#                    awaiting_fulfillment_admin_shop_orders GET    /admin/shop_orders/awaiting_fulfillment(.:format)                                                 admin/shop_orders#awaiting_fulfillment
#                           internal_notes_admin_shop_order POST   /admin/shop_orders/:id/internal_notes(.:format)                                                   admin/shop_orders#internal_notes
#                                  approve_admin_shop_order POST   /admin/shop_orders/:id/approve(.:format)                                                          admin/shop_orders#approve
#                                   reject_admin_shop_order POST   /admin/shop_orders/:id/reject(.:format)                                                           admin/shop_orders#reject
#                            place_on_hold_admin_shop_order POST   /admin/shop_orders/:id/place_on_hold(.:format)                                                    admin/shop_orders#place_on_hold
#                            take_off_hold_admin_shop_order POST   /admin/shop_orders/:id/take_off_hold(.:format)                                                    admin/shop_orders#take_off_hold
#                           mark_fulfilled_admin_shop_order POST   /admin/shop_orders/:id/mark_fulfilled(.:format)                                                   admin/shop_orders#mark_fulfilled
#                       convert_to_preauth_admin_shop_order POST   /admin/shop_orders/:id/convert_to_preauth(.:format)                                               admin/shop_orders#convert_to_preauth
#                                         admin_shop_orders GET    /admin/shop_orders(.:format)                                                                      admin/shop_orders#index
#                                                           POST   /admin/shop_orders(.:format)                                                                      admin/shop_orders#create
#                                      new_admin_shop_order GET    /admin/shop_orders/new(.:format)                                                                  admin/shop_orders#new
#                                     edit_admin_shop_order GET    /admin/shop_orders/:id/edit(.:format)                                                             admin/shop_orders#edit
#                                          admin_shop_order GET    /admin/shop_orders/:id(.:format)                                                                  admin/shop_orders#show
#                                                           PATCH  /admin/shop_orders/:id(.:format)                                                                  admin/shop_orders#update
#                                                           PUT    /admin/shop_orders/:id(.:format)                                                                  admin/shop_orders#update
#                                                           DELETE /admin/shop_orders/:id(.:format)                                                                  admin/shop_orders#destroy
#                                 internal_notes_admin_user POST   /admin/users/:id/internal_notes(.:format)                                                         admin/users#internal_notes
#                                  create_payout_admin_user POST   /admin/users/:id/create_payout(.:format)                                                          admin/users#create_payout
#                                  nuke_idv_data_admin_user POST   /admin/users/:id/nuke_idv_data(.:format)                                                          admin/users#nuke_idv_data
#                             cancel_card_grants_admin_user POST   /admin/users/:id/cancel_card_grants(.:format)                                                     admin/users#cancel_card_grants
#                                         freeze_admin_user POST   /admin/users/:id/freeze(.:format)                                                                 admin/users#freeze
#                                        defrost_admin_user POST   /admin/users/:id/defrost(.:format)                                                                admin/users#defrost
#                           grant_ship_certifier_admin_user POST   /admin/users/:id/grant_ship_certifier(.:format)                                                   admin/users#grant_ship_certifier
#                          revoke_ship_certifier_admin_user POST   /admin/users/:id/revoke_ship_certifier(.:format)                                                  admin/users#revoke_ship_certifier
#                            grant_ysws_reviewer_admin_user POST   /admin/users/:id/grant_ysws_reviewer(.:format)                                                    admin/users#grant_ysws_reviewer
#                           revoke_ysws_reviewer_admin_user POST   /admin/users/:id/revoke_ysws_reviewer(.:format)                                                   admin/users#revoke_ysws_reviewer
#                                                           POST   /admin/users/:id/block_recertification(.:format)                                                  admin/users#block_recertification
#                                                           POST   /admin/users/:id/unblock_recertification(.:format)                                                admin/users#unblock_recertification
#                              give_black_market_admin_user POST   /admin/users/:id/give_black_market(.:format)                                                      admin/users#give_black_market
#                         take_away_black_market_admin_user POST   /admin/users/:id/take_away_black_market(.:format)                                                 admin/users#take_away_black_market
#                                       ban_user_admin_user POST   /admin/users/:id/ban_user(.:format)                                                               admin/users#ban_user
#                                     unban_user_admin_user POST   /admin/users/:id/unban_user(.:format)                                                             admin/users#unban_user
#                                    impersonate_admin_user POST   /admin/users/:id/impersonate(.:format)                                                            admin/users#impersonate
#                     set_hackatime_trust_factor_admin_user POST   /admin/users/:id/set_hackatime_trust_factor(.:format)                                             admin/users#set_hackatime_trust_factor
#                              refresh_hackatime_admin_user POST   /admin/users/:id/refresh_hackatime(.:format)                                                      admin/users#refresh_hackatime
#                           grant_fraud_reviewer_admin_user POST   /admin/users/:id/grant_fraud_reviewer(.:format)                                                   admin/users#grant_fraud_reviewer
#                          revoke_fraud_reviewer_admin_user POST   /admin/users/:id/revoke_fraud_reviewer(.:format)                                                  admin/users#revoke_fraud_reviewer
#                                           flip_admin_user POST   /admin/users/:id/flip(.:format)                                                                   admin/users#flip
#                                         refill_admin_user POST   /admin/users/:id/refill(.:format)                                                                 admin/users#refill
#                                               admin_users GET    /admin/users(.:format)                                                                            admin/users#index
#                                                           GET    /admin/users/:id(.:format)                                                                        admin/users#show
#                                             admin_project DELETE /admin/projects/:id(.:format)                                                                     admin/projects#destroy
#                                     restore_admin_project PATCH  /admin/projects/:id/restore(.:format)                                                             admin/projects#restore
#                          magic_is_happening_admin_project POST   /admin/projects/:id/magic_is_happening(.:format)                                                  admin/projects#magic_is_happening
#                                                           GET    /admin/projects/:id(.:format)                                                                     admin/projects#show
#                                     invalidate_admin_vote DELETE /admin/votes/:id/invalidate(.:format)                                                             admin/votes#invalidate
#                                   uninvalidate_admin_vote PATCH  /admin/votes/:id/uninvalidate(.:format)                                                           admin/votes#uninvalidate
#                                admin_mission_control_jobs        /admin/jobs                                                                                       MissionControl::Jobs::Engine
#                                              admin_blazer        /admin/blazer                                                                                     Blazer::Engine
#                                                                  /admin/flipper                                                                                    Flipper::UI
#                                      admin_view_analytics GET    /admin/view_analytics(.:format)                                                                   admin/view_analytics#index
#                approve_admin_ship_reviewer_payout_request PATCH  /admin/ship_reviewer_payout_requests/:id/approve(.:format)                                        admin/ship_reviewer_payout_requests#approve
#                 reject_admin_ship_reviewer_payout_request PATCH  /admin/ship_reviewer_payout_requests/:id/reject(.:format)                                         admin/ship_reviewer_payout_requests#reject
#                       admin_ship_reviewer_payout_requests GET    /admin/ship_reviewer_payout_requests(.:format)                                                    admin/ship_reviewer_payout_requests#index
#                        admin_ship_reviewer_payout_request GET    /admin/ship_reviewer_payout_requests/:id(.:format)                                                admin/ship_reviewer_payout_requests#show
#                               admin_readme_certifications GET    /admin/readme_certifications(.:format)                                                            admin/readme_certifications#index
#                           edit_admin_readme_certification GET    /admin/readme_certifications/:id/edit(.:format)                                                   admin/readme_certifications#edit
#                                admin_readme_certification PATCH  /admin/readme_certifications/:id(.:format)                                                        admin/readme_certifications#update
#                                                           PUT    /admin/readme_certifications/:id(.:format)                                                        admin/readme_certifications#update
#                                admin_special_access_users GET    /admin/special_access_users(.:format)                                                             admin/special_access_users#index
#                                          admin_shop_items GET    /admin/shop_items(.:format)                                                                       admin/shop_items#index
#                                                           POST   /admin/shop_items(.:format)                                                                       admin/shop_items#create
#                                       new_admin_shop_item GET    /admin/shop_items/new(.:format)                                                                   admin/shop_items#new
#                                      edit_admin_shop_item GET    /admin/shop_items/:id/edit(.:format)                                                              admin/shop_items#edit
#                                           admin_shop_item GET    /admin/shop_items/:id(.:format)                                                                   admin/shop_items#show
#                                                           PATCH  /admin/shop_items/:id(.:format)                                                                   admin/shop_items#update
#                                                           PUT    /admin/shop_items/:id(.:format)                                                                   admin/shop_items#update
#                                                           DELETE /admin/shop_items/:id(.:format)                                                                   admin/shop_items#destroy
#                                    admin_shop_card_grants GET    /admin/shop_card_grants(.:format)                                                                 admin/shop_card_grants#index
#                                     admin_shop_card_grant GET    /admin/shop_card_grants/:id(.:format)                                                             admin/shop_card_grants#show
#                                            zap_admin_cach DELETE /admin/cache/:id/zap(.:format)                                                                    admin/caches#zap
#                                              admin_caches GET    /admin/cache(.:format)                                                                            admin/caches#index
#                                           admin_sinkening GET    /admin/sinkening/:id(.:format)                                                                    admin/sinkenings#show
#                                                           PATCH  /admin/sinkening/:id(.:format)                                                                    admin/sinkenings#update
#                                                           PUT    /admin/sinkening/:id(.:format)                                                                    admin/sinkenings#update
#                                     admin_advent_stickers GET    /admin/advent_stickers(.:format)                                                                  admin/advent_stickers#index
#                                                           POST   /admin/advent_stickers(.:format)                                                                  admin/advent_stickers#create
#                                  new_admin_advent_sticker GET    /admin/advent_stickers/new(.:format)                                                              admin/advent_stickers#new
#                                 edit_admin_advent_sticker GET    /admin/advent_stickers/:id/edit(.:format)                                                         admin/advent_stickers#edit
#                                      admin_advent_sticker PATCH  /admin/advent_stickers/:id(.:format)                                                              admin/advent_stickers#update
#                                                           PUT    /admin/advent_stickers/:id(.:format)                                                              admin/advent_stickers#update
#                                                           DELETE /admin/advent_stickers/:id(.:format)                                                              admin/advent_stickers#destroy
#                     return_to_certifier_admin_ysws_review PATCH  /admin/ysws_reviews/:id/return_to_certifier(.:format)                                             admin/ysws_reviews#return_to_certifier
#                                        admin_ysws_reviews GET    /admin/ysws_reviews(.:format)                                                                     admin/ysws_reviews#index
#                                         admin_ysws_review GET    /admin/ysws_reviews/:id(.:format)                                                                 admin/ysws_reviews#show
#                                                           PATCH  /admin/ysws_reviews/:id(.:format)                                                                 admin/ysws_reviews#update
#                                                           PUT    /admin/ysws_reviews/:id(.:format)                                                                 admin/ysws_reviews#update
#                                               leaderboard GET    /leaderboard(.:format)                                                                            leaderboard#index
#                          turbo_recede_historical_location GET    /recede_historical_location(.:format)                                                             turbo/native/navigation#recede
#                          turbo_resume_historical_location GET    /resume_historical_location(.:format)                                                             turbo/native/navigation#resume
#                         turbo_refresh_historical_location GET    /refresh_historical_location(.:format)                                                            turbo/native/navigation#refresh
#                             rails_postmark_inbound_emails POST   /rails/action_mailbox/postmark/inbound_emails(.:format)                                           action_mailbox/ingresses/postmark/inbound_emails#create
#                                rails_relay_inbound_emails POST   /rails/action_mailbox/relay/inbound_emails(.:format)                                              action_mailbox/ingresses/relay/inbound_emails#create
#                             rails_sendgrid_inbound_emails POST   /rails/action_mailbox/sendgrid/inbound_emails(.:format)                                           action_mailbox/ingresses/sendgrid/inbound_emails#create
#                       rails_mandrill_inbound_health_check GET    /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#health_check
#                             rails_mandrill_inbound_emails POST   /rails/action_mailbox/mandrill/inbound_emails(.:format)                                           action_mailbox/ingresses/mandrill/inbound_emails#create
#                              rails_mailgun_inbound_emails POST   /rails/action_mailbox/mailgun/inbound_emails/mime(.:format)                                       action_mailbox/ingresses/mailgun/inbound_emails#create
#                            rails_conductor_inbound_emails GET    /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#index
#                                                           POST   /rails/conductor/action_mailbox/inbound_emails(.:format)                                          rails/conductor/action_mailbox/inbound_emails#create
#                         new_rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/new(.:format)                                      rails/conductor/action_mailbox/inbound_emails#new
#                             rails_conductor_inbound_email GET    /rails/conductor/action_mailbox/inbound_emails/:id(.:format)                                      rails/conductor/action_mailbox/inbound_emails#show
#                  new_rails_conductor_inbound_email_source GET    /rails/conductor/action_mailbox/inbound_emails/sources/new(.:format)                              rails/conductor/action_mailbox/inbound_emails/sources#new
#                     rails_conductor_inbound_email_sources POST   /rails/conductor/action_mailbox/inbound_emails/sources(.:format)                                  rails/conductor/action_mailbox/inbound_emails/sources#create
#                     rails_conductor_inbound_email_reroute POST   /rails/conductor/action_mailbox/:inbound_email_id/reroute(.:format)                               rails/conductor/action_mailbox/reroutes#create
#                  rails_conductor_inbound_email_incinerate POST   /rails/conductor/action_mailbox/:inbound_email_id/incinerate(.:format)                            rails/conductor/action_mailbox/incinerates#create
#                                        rails_service_blob GET    /rails/active_storage/blobs/redirect/:signed_id/*filename(.:format)                               active_storage/blobs/redirect#show
#                                  rails_service_blob_proxy GET    /rails/active_storage/blobs/proxy/:signed_id/*filename(.:format)                                  active_storage/blobs/proxy#show
#                                                           GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                                        active_storage/blobs/redirect#show
#                                 rails_blob_representation GET    /rails/active_storage/representations/redirect/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations/redirect#show
#                           rails_blob_representation_proxy GET    /rails/active_storage/representations/proxy/:signed_blob_id/:variation_key/*filename(.:format)    active_storage/representations/proxy#show
#                                                           GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format)          active_storage/representations/redirect#show
#                                        rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                                       active_storage/disk#show
#                                 update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                               active_storage/disk#update
#                                      rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                                    active_storage/direct_uploads#create
#
# Routes for ActiveInsights::Engine:
#                        requests GET  /requests(.:format)                                            active_insights/requests#index
#                            jobs GET  /jobs(.:format)                                                active_insights/jobs#index
#                                 GET  /jobs/:date(.:format)                                          active_insights/jobs#index
#                                 GET  /requests/:date(.:format)                                      active_insights/requests#index
#                 rpm_redirection GET  /requests/rpm/redirection(.:format)                            active_insights/rpm#redirection
#                             rpm GET  /requests/:date/rpm(.:format)                                  active_insights/rpm#index
#   requests_p_values_redirection GET  /requests/p_values/redirection(.:format)                       active_insights/requests_p_values#redirection
#               requests_p_values GET  /requests/:date/p_values(.:format)                             active_insights/requests_p_values#index
#             controller_p_values GET  /requests/:date/:formatted_controller/p_values(.:format)       active_insights/requests_p_values#index
# controller_p_values_redirection GET  /requests/:formatted_controller/p_values/redirection(.:format) active_insights/requests_p_values#redirection
#                 jpm_redirection GET  /jobs/jpm/redirection(.:format)                                active_insights/jpm#redirection
#                             jpm GET  /jobs/:date/jpm(.:format)                                      active_insights/jpm#index
#       jobs_p_values_redirection GET  /jobs/p_values/redirection(.:format)                           active_insights/jobs_p_values#redirection
#                   jobs_p_values GET  /jobs/:date/p_values(.:format)                                 active_insights/jobs_p_values#index
#                    job_p_values GET  /jobs/:date/:job/p_values(.:format)                            active_insights/jobs_p_values#index
#        job_p_values_redirection GET  /jobs/:job/p_values/redirection(.:format)                      active_insights/jobs_p_values#redirection
#                    jobs_latency GET  /jobs/:date/latencies(.:format)                                active_insights/jobs_latencies#index
#        jobs_latency_redirection GET  /jobs/latencies/redirection(.:format)                          active_insights/jobs_latencies#redirection
#                            root GET  /                                                              active_insights/requests#index
#
# Routes for MissionControl::Jobs::Engine:
#     application_queue_pause DELETE /applications/:application_id/queues/:queue_id/pause(.:format) mission_control/jobs/queues/pauses#destroy
#                             POST   /applications/:application_id/queues/:queue_id/pause(.:format) mission_control/jobs/queues/pauses#create
#          application_queues GET    /applications/:application_id/queues(.:format)                 mission_control/jobs/queues#index
#           application_queue GET    /applications/:application_id/queues/:id(.:format)             mission_control/jobs/queues#show
#       application_job_retry POST   /applications/:application_id/jobs/:job_id/retry(.:format)     mission_control/jobs/retries#create
#     application_job_discard POST   /applications/:application_id/jobs/:job_id/discard(.:format)   mission_control/jobs/discards#create
#    application_job_dispatch POST   /applications/:application_id/jobs/:job_id/dispatch(.:format)  mission_control/jobs/dispatches#create
#    application_bulk_retries POST   /applications/:application_id/jobs/bulk_retries(.:format)      mission_control/jobs/bulk_retries#create
#   application_bulk_discards POST   /applications/:application_id/jobs/bulk_discards(.:format)     mission_control/jobs/bulk_discards#create
#             application_job GET    /applications/:application_id/jobs/:id(.:format)               mission_control/jobs/jobs#show
#            application_jobs GET    /applications/:application_id/:status/jobs(.:format)           mission_control/jobs/jobs#index
#         application_workers GET    /applications/:application_id/workers(.:format)                mission_control/jobs/workers#index
#          application_worker GET    /applications/:application_id/workers/:id(.:format)            mission_control/jobs/workers#show
# application_recurring_tasks GET    /applications/:application_id/recurring_tasks(.:format)        mission_control/jobs/recurring_tasks#index
#  application_recurring_task GET    /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#show
#                             PATCH  /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#update
#                             PUT    /applications/:application_id/recurring_tasks/:id(.:format)    mission_control/jobs/recurring_tasks#update
#                      queues GET    /queues(.:format)                                              mission_control/jobs/queues#index
#                       queue GET    /queues/:id(.:format)                                          mission_control/jobs/queues#show
#                         job GET    /jobs/:id(.:format)                                            mission_control/jobs/jobs#show
#                        jobs GET    /:status/jobs(.:format)                                        mission_control/jobs/jobs#index
#                        root GET    /                                                              mission_control/jobs/queues#index
#
# Routes for Blazer::Engine:
#       run_queries POST   /queries/run(.:format)            blazer/queries#run
#    cancel_queries POST   /queries/cancel(.:format)         blazer/queries#cancel
#     refresh_query POST   /queries/:id/refresh(.:format)    blazer/queries#refresh
#    tables_queries GET    /queries/tables(.:format)         blazer/queries#tables
#    schema_queries GET    /queries/schema(.:format)         blazer/queries#schema
#      docs_queries GET    /queries/docs(.:format)           blazer/queries#docs
#           queries GET    /queries(.:format)                blazer/queries#index
#                   POST   /queries(.:format)                blazer/queries#create
#         new_query GET    /queries/new(.:format)            blazer/queries#new
#        edit_query GET    /queries/:id/edit(.:format)       blazer/queries#edit
#             query GET    /queries/:id(.:format)            blazer/queries#show
#                   PATCH  /queries/:id(.:format)            blazer/queries#update
#                   PUT    /queries/:id(.:format)            blazer/queries#update
#                   DELETE /queries/:id(.:format)            blazer/queries#destroy
#         run_check GET    /checks/:id/run(.:format)         blazer/checks#run
#            checks GET    /checks(.:format)                 blazer/checks#index
#                   POST   /checks(.:format)                 blazer/checks#create
#         new_check GET    /checks/new(.:format)             blazer/checks#new
#        edit_check GET    /checks/:id/edit(.:format)        blazer/checks#edit
#             check PATCH  /checks/:id(.:format)             blazer/checks#update
#                   PUT    /checks/:id(.:format)             blazer/checks#update
#                   DELETE /checks/:id(.:format)             blazer/checks#destroy
# refresh_dashboard POST   /dashboards/:id/refresh(.:format) blazer/dashboards#refresh
#        dashboards POST   /dashboards(.:format)             blazer/dashboards#create
#     new_dashboard GET    /dashboards/new(.:format)         blazer/dashboards#new
#    edit_dashboard GET    /dashboards/:id/edit(.:format)    blazer/dashboards#edit
#         dashboard GET    /dashboards/:id(.:format)         blazer/dashboards#show
#                   PATCH  /dashboards/:id(.:format)         blazer/dashboards#update
#                   PUT    /dashboards/:id(.:format)         blazer/dashboards#update
#                   DELETE /dashboards/:id(.:format)         blazer/dashboards#destroy
#              root GET    /                                 blazer/queries#home

class AdminConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.is_admin?
  end
end

class ShipCertifierConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin_or_ship_certifier?
  end
end

class FraudTeamConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.is_admin? || user&.fraud_team_member?
  end
end

class YswsReviewerConstraint
  def self.matches?(request)
    return false unless request.session[:user_id]

    user = User.find_by(id: request.session[:user_id])
    user&.admin_or_ysws_reviewer?
  end
end

Rails.application.routes.draw do
  get "/showcase", to: "showcase#new", as: :showcase
  post "/showcase", to: "showcase#create"
  mount ActiveInsights::Engine => "/insights"
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
  post "/mailing-list-signup", to: "landing#mailing_list_signup"

  # Authentication routes
  get "/auth/slack", to: "sessions#new"
  get "/auth/slack/callback", to: "sessions#create", as: :slack_callback
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy", as: :logout
  delete "/stop_impersonating", to: "sessions#stop_impersonating", as: :stop_impersonating

  # Development auto-login (only available in development)
  if Rails.env.development?
    get "/auth/dev_login", to: "sessions#auto_login_dev", as: :dev_auto_login
  end

  get "/magic-link", to: "sessions#magic_link", as: :magic_link # For users signing in
  post "/explorpheus/magic-link", to: "magic_link#get_secret_magic_url" # For the welcome bot to fetch the magic link.

  # Identity Vault routes
  get "users/identity_vault_callback", to: "users#identity_vault_callback", as: :identity_vault_callback
  get "users/link_identity_vault", to: "users#link_identity_vault", as: :link_identity_vault

  # Tutorial
  get "tutorial/todo_modal", to: "tutorials#todo_modal"

  get "users/hackatime_auth_redirect", to: "users#hackatime_auth_redirect", as: :hackatime_auth_redirect

  # Dashboard
  # get "dashboard", to: "dashboard#index"

  get "explore", to: "explore#index", as: :explore
  get "explore/following", to: "explore#following", as: :explore_following
  get "explore/gallery", to: "explore#gallery", as: :explore_gallery

  get "my_projects", to: "projects#my_projects"
  post "check_link", to: "projects#check_link"
  get "check_github_readme", to: "projects#check_github_readme"
  get "wrapped", to: "wrapped#show"
  get "wrapped/share/:share_token", to: "wrapped#share", as: :shared_wrapped
  get "campfire", to: "campfire#index"
  get "campfire/hackatime_status", to: "campfire#hackatime_status"

  get "/map", to: "map#index", as: :map

  # Global timer session check - must be before projects resource
  get "timer_sessions/active", to: "timer_sessions#global_active"

  resources :projects do
    resources :devlogs, only: [ :create, :destroy, :update ]
    resources :timer_sessions, only: [ :create, :update, :show, :destroy ] do
      collection do
        get :active
      end
    end

    # Projects::FollowsController
    post "follow", to: "projects/follows#create", as: :follow
    delete "unfollow", to: "projects/follows#destroy", as: :unfollow

    # Projects::ReadmesController
    get "readme", to: "projects/readmes#show", as: :readme

    # Projects::RecertificationsController
    resource :recertification, only: [ :create ], controller: "projects/recertifications"

    # Projects::ShipsController
    resource :ship, only: [ :create ], controller: "projects/ships"

    member do
      post :stake_stonks
      delete :unstake_stonks
      patch :update_coordinates
      delete :unplace_coordinates
      # patch :recover
      get "devlog/:devlog_id", action: :show, as: :devlog
    end
  end

  resources :votes, only: [ :new, :create ] do
    collection do
      get :locked
      post "track_demo/:position", to: "votes#track_demo", as: :track_demo
      post "track_repo/:position", to: "votes#track_repo", as: :track_repo
    end
  end

  resources :fraud_reports, only: [ :create ]

  scope :shop do
    get "/", to: "shop_items#index", as: :shop
    get "/black_market", to: "shop_items#black_market", as: :black_market
    resources :shop_items, except: [ :index ], path: :items do
      member do
        get :buy, to: "shop_orders#new", as: :order
        post :buy, to: "shop_orders#create", as: :checkout
      end
    end
    resources :shop_orders, path: :orders, except: %i[new]
  end

  resources :users, only: [ :show ] do
    resource :profile, controller: "user/profiles", only: [ :edit, :update ]
  end

  # Payouts etc
  get "/payouts/:slack_id", to: "payouts#index"

  get "/404", to: "errors#not_found"
  get "/500", to: "errors#internal_server"

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
  post "tutorial/complete_new_tutorial_step", to: "tutorial_progress#complete_new_step", as: :complete_new_tutorial_step

  get "/payouts", to: "payouts#index"
  resources :ship_reviewer_payout_requests, only: [ :create, :index ]

  # API routes
  namespace :api do
    namespace :v1 do
      get "users/me", to: "users#me"
      resources :projects, only: [ :index, :show ] do
        collection do
          get :shipped
        end
      end
      resources :users, only: [ :index, :show ]
      resources :devlogs, only: [ :index, :show ]
      resources :comments, only: [ :index, :show ]
      resources :emotes, only: [ :show ]
    end

    namespace :v2 do
      resources :projects, only: [ :index, :show ] do
        collection do
          get :search
        end
      end
      resources :users, only: [ :index, :show ] do
        collection do
          get :search
        end
      end
      resources :devlogs, only: [ :index, :show ]
      resources :payouts, only: [ :index, :show ]
      get "/", to: "base#index"
    end
  end
  get "api/check_user", to: "users#check_user"
  post "api/devlogs", to: "devlogs#api_create"

  resources :ship_event_feedbacks

  post "track_view", to: "view_tracking#create"

  get "/gork", to: "static_pages#gork"
  get "/s", to: "static_pages#s", as: :stt

  namespace :admin do
    constraints ShipCertifierConstraint do
      resources :ship_certifications, only: [ :index, :edit, :update ] do
        collection do
          get :logs
        end
      end
      resources :low_quality_dashboard, only: [ :index ] do
        collection do
          post :mark_low_quality
          post :mark_ok
          post :message_repeat_offender
        end
      end
      resources :users, only: [ :show ] do
        member do
          post :block_recertification
          post :unblock_recertification
        end
      end
    end

    constraints FraudTeamConstraint do
      get "/", to: "static_pages#index", as: :root
      resources :fraud_reports, only: [ :index, :show ] do
        member do
          get :resolve
          get :unresolve
          patch :resolve
          patch :unresolve
        end
      end
      resources :fulfillment_dashboard, only: [ :index ] do
      collection do
        post :send_letter_mail
      end
    end
      resources :voting_dashboard, only: [ :index ]
      resources :payouts_dashboard, only: [ :index ]
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
          post :convert_to_preauth
        end
      end
      resources :users, only: [ :index, :show ] do
        member do
          post :internal_notes
          post :create_payout
          post :nuke_idv_data
          post :cancel_card_grants
          post :freeze
          post :defrost
          post :grant_ship_certifier
          post :revoke_ship_certifier
          post :grant_ysws_reviewer
          post :revoke_ysws_reviewer
          post :block_recertification
          post :unblock_recertification
          post :give_black_market
          post :take_away_black_market
          post :ban_user
          post :unban_user
          post :impersonate
          post :set_hackatime_trust_factor
          post :refresh_hackatime
          post :grant_fraud_reviewer
          post :revoke_fraud_reviewer
          post :flip
          post :refill
        end
      end
      resources :projects, only: [ :show ] do
        member do
          delete :destroy
          patch :restore
          post :magic_is_happening
        end
      end
      resources :votes, only: [] do
        member do
          delete :invalidate
          patch :uninvalidate
        end
      end
    end

    constraints AdminConstraint do
      mount MissionControl::Jobs::Engine, at: "jobs"
      # mount AhoyCaptain::Engine, at: "ahoy_captain"
      mount Blazer::Engine, at: "blazer"
      mount Flipper::UI.app(Flipper), at: "flipper"
      # mount_avo
      resources :view_analytics, only: [ :index ]
      resources :ship_reviewer_payout_requests, only: [ :index, :show ] do
        member do
          patch :approve
          patch :reject
        end
      end
      resources :readme_certifications, only: [ :index, :edit, :update ]
      resources :special_access_users, only: [ :index ]
      resources :shop_items
      resources :shop_card_grants, only: [ :index, :show ]
      resources :caches, path: "cache", only: [ :index ] do
        member do
          delete :zap
        end
      end
      resources :sinkenings, only: [ :show, :update ], path: "sinkening"
      resources :advent_stickers, only: [ :index, :new, :create, :edit, :update, :destroy ]
    end

    constraints YswsReviewerConstraint do
      resources :ysws_reviews, only: [ :index, :show, :update ] do
        member do
          patch :return_to_certifier
        end
      end
    end
  end

  get "leaderboard", to: "leaderboard#index"
end
