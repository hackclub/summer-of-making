# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_29_193720) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_insights_jobs", force: :cascade do |t|
    t.string "job"
    t.string "queue"
    t.float "db_runtime"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "uuid"
    t.float "duration"
    t.float "queue_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["started_at", "duration", "queue_time"], name: "idx_on_started_at_duration_queue_time_010695b74f"
    t.index ["started_at", "duration"], name: "index_active_insights_jobs_on_started_at_and_duration"
    t.index ["started_at"], name: "index_active_insights_jobs_on_started_at"
  end

  create_table "active_insights_requests", force: :cascade do |t|
    t.string "controller"
    t.string "action"
    t.string "format"
    t.string "http_method"
    t.text "path"
    t.integer "status"
    t.float "view_runtime"
    t.float "db_runtime"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "uuid"
    t.float "duration"
    t.virtual "formatted_controller", type: :string, as: "(((controller)::text || '#'::text) || (action)::text)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.index ["started_at", "duration"], name: "index_active_insights_requests_on_started_at_and_duration"
    t.index ["started_at", "formatted_controller"], name: "idx_on_started_at_formatted_controller_5d659a01d9"
    t.index ["started_at"], name: "index_active_insights_requests_on_started_at"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", force: :cascade do |t|
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["properties"], name: "index_ahoy_events_on_properties", opclass: :jsonb_path_ops, using: :gin
    t.index ["time"], name: "index_ahoy_events_on_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["started_at"], name: "index_ahoy_visits_on_started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "airtable_high_seas_book_story_submissions", force: :cascade do |t|
    t.string "airtable_id"
    t.jsonb "airtable_fields"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "airtable_syncs", force: :cascade do |t|
    t.string "syncable_type", null: false
    t.bigint "syncable_id", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "airtable_record_id"
    t.index ["last_synced_at"], name: "index_airtable_syncs_on_last_synced_at"
    t.index ["syncable_type", "syncable_id"], name: "index_airtable_syncs_on_syncable"
    t.index ["syncable_type", "syncable_id"], name: "index_airtable_syncs_on_syncable_type_and_syncable_id", unique: true
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "devlog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "rich_content"
    t.text "content"
    t.index ["devlog_id"], name: "index_comments_on_devlog_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "daily_stonk_reports", force: :cascade do |t|
    t.text "report", null: false
    t.date "date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_stonk_reports_on_date", unique: true
  end

  create_table "devlogs", force: :cascade do |t|
    t.text "text"
    t.string "attachment"
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_hackatime_time"
    t.integer "seconds_coded"
    t.integer "likes_count", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "hackatime_pulled_at"
    t.integer "views_count", default: 0, null: false
    t.integer "duration_seconds", default: 0, null: false
    t.jsonb "hackatime_projects_key_snapshot", default: [], null: false
    t.boolean "is_neighborhood_migrated", default: false, null: false
    t.boolean "for_sinkening", default: false, null: false
    t.index ["project_id"], name: "index_devlogs_on_project_id"
    t.index ["user_id"], name: "index_devlogs_on_user_id"
    t.index ["views_count"], name: "index_devlogs_on_views_count"
  end

  create_table "email_signups", force: :cascade do |t|
    t.text "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.inet "ip"
    t.string "user_agent"
    t.string "ref"
    t.datetime "synced_at"
    t.string "slack_id"
    t.index ["email"], name: "index_email_signups_on_email", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "fraud_reports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "suspect_type"
    t.bigint "suspect_id"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "resolved", default: false, null: false
    t.index ["user_id", "suspect_type", "suspect_id"], name: "index_fraud_reports_on_user_and_suspect", unique: true
    t.index ["user_id"], name: "index_fraud_reports_on_user_id"
  end

  create_table "hackatime_projects", force: :cascade do |t|
    t.string "name"
    t.integer "seconds"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_hackatime_projects_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_hackatime_projects_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "likeable_type", null: false
    t.bigint "likeable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_id_and_likeable_type_and_likeable_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "magic_links", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_magic_links_on_user_id"
  end

  create_table "payouts", force: :cascade do |t|
    t.decimal "amount", precision: 6, scale: 2
    t.string "payable_type"
    t.bigint "payable_id"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.boolean "escrowed", default: false, null: false
    t.index ["created_at", "amount"], name: "index_payouts_on_created_at_and_amount"
    t.index ["created_at", "payable_type", "amount"], name: "index_payouts_on_date_type_amount"
    t.index ["created_at"], name: "index_payouts_on_created_at"
    t.index ["escrowed"], name: "index_payouts_on_escrowed"
    t.index ["payable_type", "payable_id"], name: "index_payouts_on_payable"
    t.index ["payable_type"], name: "index_payouts_on_payable_type"
    t.index ["user_id"], name: "index_payouts_on_user_id"
  end

  create_table "project_follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_follows_on_project_id"
    t.index ["user_id", "project_id"], name: "index_project_follows_on_user_id_and_project_id", unique: true
    t.index ["user_id"], name: "index_project_follows_on_user_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "readme_link"
    t.string "demo_link"
    t.string "repo_link"
    t.integer "rating"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.boolean "is_shipped", default: false
    t.string "hackatime_project_keys", default: [], array: true
    t.boolean "is_deleted", default: false
    t.boolean "used_ai"
    t.boolean "ysws_submission", default: false, null: false
    t.string "ysws_type"
    t.integer "devlogs_count", default: 0, null: false
    t.integer "certification_type"
    t.integer "views_count", default: 0, null: false
    t.float "x"
    t.float "y"
    t.boolean "is_sinkening_ship"
    t.index ["is_shipped"], name: "index_projects_on_is_shipped"
    t.index ["user_id"], name: "index_projects_on_user_id"
    t.index ["views_count"], name: "index_projects_on_views_count"
    t.index ["x", "y"], name: "index_projects_on_x_and_y"
  end

  create_table "readme_certifications", force: :cascade do |t|
    t.bigint "reviewer_id"
    t.bigint "project_id", null: false
    t.integer "judgement", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "judgement"], name: "index_readme_certifications_on_project_id_and_judgement"
    t.index ["project_id"], name: "index_readme_certifications_on_project_id"
    t.index ["reviewer_id"], name: "index_readme_certifications_on_reviewer_id"
  end

  create_table "readme_checks", force: :cascade do |t|
    t.string "readme_link"
    t.string "content"
    t.integer "status", default: 0, null: false
    t.integer "decision"
    t.string "reason"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_readme_checks_on_project_id"
  end

  create_table "ship_certifications", force: :cascade do |t|
    t.bigint "reviewer_id"
    t.bigint "project_id", null: false
    t.integer "judgement", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ysws_feedback_reasons"
    t.bigint "ysws_returned_by_id"
    t.datetime "ysws_returned_at"
    t.index ["project_id", "judgement"], name: "index_ship_certifications_on_project_id_and_judgement"
    t.index ["project_id"], name: "index_ship_certifications_on_project_id"
    t.index ["reviewer_id"], name: "index_ship_certifications_on_reviewer_id"
    t.index ["ysws_returned_by_id"], name: "index_ship_certifications_on_ysws_returned_by_id"
  end

  create_table "ship_event_feedbacks", force: :cascade do |t|
    t.bigint "ship_event_id", null: false
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ship_event_id"], name: "index_ship_event_feedbacks_on_ship_event_id"
  end

  create_table "ship_events", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "for_sinkening", default: false, null: false
    t.boolean "excluded_from_pool", default: false, null: false
    t.index ["project_id"], name: "index_ship_events_on_project_id"
  end

  create_table "shipwright_advices", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "ship_certification_id", null: false
    t.text "description"
    t.string "proof_link"
    t.integer "status", default: 0
    t.integer "shell_reward", default: 0
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "status"], name: "index_shipwright_advices_on_project_id_and_status"
    t.index ["project_id"], name: "index_shipwright_advices_on_project_id"
    t.index ["ship_certification_id"], name: "index_shipwright_advices_on_ship_certification_id"
  end

  create_table "shop_card_grants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shop_item_id", null: false
    t.string "hcb_grant_hashid"
    t.integer "expected_amount_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_item_id"], name: "index_shop_card_grants_on_shop_item_id"
    t.index ["user_id"], name: "index_shop_card_grants_on_user_id"
  end

  create_table "shop_items", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "description"
    t.string "internal_description"
    t.decimal "usd_cost", precision: 6, scale: 2
    t.decimal "ticket_cost", precision: 6, scale: 2
    t.integer "hacker_score", default: 0
    t.boolean "requires_black_market"
    t.string "hcb_merchant_lock"
    t.string "hcb_category_lock"
    t.string "hcb_keyword_lock"
    t.jsonb "agh_contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "one_per_person_ever", default: false
    t.integer "max_qty", default: 10
    t.boolean "show_in_carousel"
    t.boolean "limited", default: false
    t.integer "stock"
    t.text "under_the_fold_description"
    t.boolean "enabled_us", default: false
    t.boolean "enabled_eu", default: false
    t.boolean "enabled_in", default: false
    t.boolean "enabled_ca", default: false
    t.boolean "enabled_au", default: false
    t.boolean "enabled_xx", default: false
    t.decimal "price_offset_us", precision: 6, scale: 2, default: "0.0"
    t.decimal "price_offset_eu", precision: 6, scale: 2, default: "0.0"
    t.decimal "price_offset_in", precision: 6, scale: 2, default: "0.0"
    t.decimal "price_offset_ca", precision: 6, scale: 2, default: "0.0"
    t.decimal "price_offset_au", precision: 6, scale: 2, default: "0.0"
    t.decimal "price_offset_xx", precision: 6, scale: 2, default: "0.0"
    t.boolean "enabled"
    t.integer "site_action"
    t.text "hcb_preauthorization_instructions"
    t.check_constraint "hacker_score >= 0 AND hacker_score <= 100", name: "hacker_score_percentage_check"
  end

  create_table "shop_orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shop_item_id", null: false
    t.decimal "frozen_item_price", precision: 6, scale: 2
    t.integer "quantity"
    t.jsonb "frozen_address"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rejection_reason"
    t.string "external_ref"
    t.datetime "awaiting_periodical_fulfillment_at"
    t.datetime "fulfilled_at"
    t.datetime "rejected_at"
    t.datetime "on_hold_at"
    t.text "internal_notes"
    t.bigint "shop_card_grant_id"
    t.decimal "fulfillment_cost", precision: 6, scale: 2, default: "0.0"
    t.string "fulfilled_by"
    t.bigint "warehouse_package_id"
    t.index ["shop_card_grant_id"], name: "index_shop_orders_on_shop_card_grant_id"
    t.index ["shop_item_id"], name: "index_shop_orders_on_shop_item_id"
    t.index ["user_id"], name: "index_shop_orders_on_user_id"
    t.index ["warehouse_package_id"], name: "index_shop_orders_on_warehouse_package_id"
  end

  create_table "shop_warehouse_packages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "frozen_address", null: false
    t.string "theseus_package_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["theseus_package_id"], name: "index_shop_warehouse_packages_on_theseus_package_id", unique: true
    t.index ["user_id"], name: "index_shop_warehouse_packages_on_user_id"
  end

  create_table "sinkening_settings", force: :cascade do |t|
    t.float "intensity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slack_story_url"
  end

  create_table "slack_emotes", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "slack_id", null: false
    t.boolean "is_active", default: true, null: false
    t.string "created_by"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_slack_emotes_on_name", unique: true
    t.index ["slack_id"], name: "index_slack_emotes_on_slack_id", unique: true
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stonk_ticklers", force: :cascade do |t|
    t.text "tickler", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_stonk_ticklers_on_project_id"
  end

  create_table "stonks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_stonks_on_project_id"
    t.index ["user_id"], name: "index_stonks_on_user_id"
  end

  create_table "timer_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.bigint "devlog_id"
    t.datetime "started_at", null: false
    t.datetime "last_paused_at"
    t.integer "accumulated_paused", default: 0, null: false
    t.datetime "stopped_at"
    t.integer "net_time", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["devlog_id"], name: "index_timer_sessions_on_devlog_id"
    t.index ["project_id"], name: "index_timer_sessions_on_project_id"
    t.index ["user_id"], name: "index_timer_sessions_on_user_id"
  end

  create_table "tutorial_progresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "step_progress", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "soft_tutorial_steps", default: {}, null: false
    t.index ["user_id"], name: "index_tutorial_progresses_on_user_id"
  end

  create_table "user_badges", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "badge_key", null: false
    t.datetime "earned_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_key"], name: "index_user_badges_on_badge_key"
    t.index ["user_id", "badge_key"], name: "index_user_badges_on_user_id_and_badge_key", unique: true
    t.index ["user_id"], name: "index_user_badges_on_user_id"
  end

  create_table "user_hackatime_data", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "data", default: {}
    t.datetime "last_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_hackatime_data_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.text "bio"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "custom_css"
    t.boolean "hide_from_logged_out", default: false
    t.string "balloon_color"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "user_vote_queues", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "ship_event_pairs", default: [], null: false
    t.integer "current_position", default: 0, null: false
    t.datetime "last_generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_position"], name: "index_user_vote_queues_on_current_position"
    t.index ["last_generated_at"], name: "index_user_vote_queues_on_last_generated_at"
    t.index ["user_id"], name: "index_user_vote_queues_on_user_id"
    t.index ["user_id"], name: "index_user_vote_queues_on_user_id_unique", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "slack_id"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "display_name"
    t.string "timezone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.boolean "has_commented", default: false
    t.boolean "has_hackatime", default: false
    t.boolean "is_admin", default: false, null: false
    t.string "identity_vault_id"
    t.string "identity_vault_access_token"
    t.boolean "ysws_verified", default: false
    t.text "internal_notes"
    t.boolean "has_black_market"
    t.boolean "has_hackatime_account"
    t.boolean "has_clicked_completed_tutorial_modal", default: false, null: false
    t.boolean "tutorial_video_seen", default: false, null: false
    t.boolean "freeze_shop_activity", default: false
    t.datetime "synced_at", precision: nil
    t.text "permissions", default: "[]"
    t.jsonb "shenanigans_state", default: {}
    t.boolean "is_banned", default: false
    t.boolean "fraud_team_member", default: false, null: false
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.jsonb "object_changes"
    t.jsonb "extra_data"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "view_events", force: :cascade do |t|
    t.string "viewable_type", null: false
    t.bigint "viewable_id", null: false
    t.bigint "user_id"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_view_events_on_created_at"
    t.index ["user_id"], name: "index_view_events_on_user_id"
    t.index ["viewable_type", "viewable_id", "created_at"], name: "idx_on_viewable_type_viewable_id_created_at_95fa2a7c9e"
    t.index ["viewable_type", "viewable_id"], name: "index_view_events_on_viewable"
  end

  create_table "vote_changes", force: :cascade do |t|
    t.bigint "vote_id", null: false
    t.bigint "project_id", null: false
    t.integer "elo_before", null: false
    t.integer "elo_after", null: false
    t.integer "elo_delta", null: false
    t.string "result", null: false
    t.integer "project_vote_count", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_vote_changes_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_vote_changes_on_project_id"
    t.index ["result"], name: "index_vote_changes_on_result"
    t.index ["vote_id"], name: "index_vote_changes_on_vote_id"
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "explanation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "project_1_demo_opened", default: false
    t.boolean "project_1_repo_opened", default: false
    t.boolean "project_2_demo_opened", default: false
    t.boolean "project_2_repo_opened", default: false
    t.integer "time_spent_voting_ms"
    t.boolean "music_played"
    t.string "status", default: "active", null: false
    t.text "invalid_reason"
    t.datetime "marked_invalid_at"
    t.bigint "marked_invalid_by_id"
    t.bigint "project_1_id"
    t.bigint "project_2_id"
    t.bigint "ship_event_1_id", null: false
    t.bigint "ship_event_2_id", null: false
    t.datetime "processed_at"
    t.text "ai_feedback"
    t.boolean "is_low_quality", default: false, null: false
    t.index ["marked_invalid_at"], name: "index_votes_on_marked_invalid_at"
    t.index ["marked_invalid_by_id"], name: "index_votes_on_marked_invalid_by_id"
    t.index ["project_1_id"], name: "index_votes_on_project_1_id"
    t.index ["project_2_id"], name: "index_votes_on_project_2_id"
    t.index ["ship_event_1_id"], name: "index_votes_on_ship_event_1_id"
    t.index ["ship_event_2_id"], name: "index_votes_on_ship_event_2_id"
    t.index ["status"], name: "index_votes_on_status"
    t.index ["user_id", "ship_event_1_id", "ship_event_2_id"], name: "index_votes_on_user_and_ship_events", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "ysws_review_devlog_approvals", force: :cascade do |t|
    t.bigint "devlog_id", null: false
    t.bigint "user_id", null: false, comment: "The reviewer who made this approval"
    t.boolean "approved", null: false
    t.integer "approved_seconds", comment: "Seconds approved by reviewer (may differ from devlog.duration_seconds)"
    t.text "notes", comment: "Internal notes from the reviewer"
    t.datetime "reviewed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["devlog_id"], name: "index_ysws_review_devlog_approvals_on_devlog_id", unique: true
    t.index ["user_id"], name: "index_ysws_review_devlog_approvals_on_user_id"
  end

  create_table "ysws_review_submissions", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "reviewer_id", null: false
    t.index ["project_id"], name: "index_ysws_review_submissions_on_project_id", unique: true
    t.index ["reviewer_id"], name: "index_ysws_review_submissions_on_reviewer_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "devlogs"
  add_foreign_key "comments", "users"
  add_foreign_key "devlogs", "projects"
  add_foreign_key "devlogs", "users"
  add_foreign_key "fraud_reports", "users"
  add_foreign_key "hackatime_projects", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "magic_links", "users"
  add_foreign_key "project_follows", "projects"
  add_foreign_key "project_follows", "users"
  add_foreign_key "projects", "users"
  add_foreign_key "readme_certifications", "projects"
  add_foreign_key "readme_certifications", "users", column: "reviewer_id"
  add_foreign_key "readme_checks", "projects"
  add_foreign_key "ship_certifications", "projects"
  add_foreign_key "ship_certifications", "users", column: "reviewer_id"
  add_foreign_key "ship_certifications", "users", column: "ysws_returned_by_id"
  add_foreign_key "ship_event_feedbacks", "ship_events"
  add_foreign_key "ship_events", "projects"
  add_foreign_key "shipwright_advices", "projects"
  add_foreign_key "shipwright_advices", "ship_certifications"
  add_foreign_key "shop_card_grants", "shop_items"
  add_foreign_key "shop_card_grants", "users"
  add_foreign_key "shop_orders", "shop_card_grants"
  add_foreign_key "shop_orders", "shop_items"
  add_foreign_key "shop_orders", "shop_warehouse_packages", column: "warehouse_package_id"
  add_foreign_key "shop_orders", "users"
  add_foreign_key "shop_warehouse_packages", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stonk_ticklers", "projects"
  add_foreign_key "stonks", "projects"
  add_foreign_key "stonks", "users"
  add_foreign_key "timer_sessions", "devlogs"
  add_foreign_key "timer_sessions", "projects"
  add_foreign_key "timer_sessions", "users"
  add_foreign_key "tutorial_progresses", "users"
  add_foreign_key "user_badges", "users"
  add_foreign_key "user_hackatime_data", "users"
  add_foreign_key "user_profiles", "users"
  add_foreign_key "user_vote_queues", "users"
  add_foreign_key "view_events", "users"
  add_foreign_key "vote_changes", "projects"
  add_foreign_key "vote_changes", "votes"
  add_foreign_key "votes", "projects", column: "project_1_id"
  add_foreign_key "votes", "projects", column: "project_2_id"
  add_foreign_key "votes", "ship_events", column: "ship_event_1_id"
  add_foreign_key "votes", "ship_events", column: "ship_event_2_id"
  add_foreign_key "votes", "users"
  add_foreign_key "votes", "users", column: "marked_invalid_by_id"
  add_foreign_key "ysws_review_devlog_approvals", "devlogs"
  add_foreign_key "ysws_review_devlog_approvals", "users"
  add_foreign_key "ysws_review_submissions", "projects"
  add_foreign_key "ysws_review_submissions", "users", column: "reviewer_id"
end
