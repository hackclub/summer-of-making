# Deleting a user cascades through everything they own. Financial, fraud, vote and
# review records are kept but detached from the account (on_delete: :nullify).
class CascadeUserDeletion < ActiveRecord::Migration[8.0]
  CASCADE = [
    [ :comments, :devlogs, :devlog_id ],
    [ :comments, :users, :user_id ],
    [ :devlogs, :projects, :project_id ],
    [ :devlogs, :users, :user_id ],
    [ :hackatime_projects, :users, :user_id ],
    [ :likes, :users, :user_id ],
    [ :magic_links, :users, :user_id ],
    [ :project_follows, :projects, :project_id ],
    [ :project_follows, :users, :user_id ],
    [ :project_languages, :projects, :project_id ],
    [ :projects, :users, :user_id ],
    [ :readme_certifications, :projects, :project_id ],
    [ :readme_checks, :projects, :project_id ],
    [ :ship_certifications, :projects, :project_id ],
    [ :ship_event_feedbacks, :ship_events, :ship_event_id ],
    [ :ship_events, :projects, :project_id ],
    [ :shipwright_advices, :projects, :project_id ],
    [ :shipwright_advices, :ship_certifications, :ship_certification_id ],
    [ :stonk_ticklers, :projects, :project_id ],
    [ :stonks, :projects, :project_id ],
    [ :stonks, :users, :user_id ],
    [ :timer_sessions, :devlogs, :devlog_id ],
    [ :timer_sessions, :projects, :project_id ],
    [ :timer_sessions, :users, :user_id ],
    [ :tutorial_progresses, :users, :user_id ],
    [ :user_advent_stickers, :devlogs, :devlog_id ],
    [ :user_advent_stickers, :users, :user_id ],
    [ :user_badges, :users, :user_id ],
    [ :user_hackatime_data, :users, :user_id ],
    [ :user_profiles, :users, :user_id ],
    [ :user_vote_queues, :users, :user_id ],
    [ :view_events, :users, :user_id ],
    [ :vote_changes, :projects, :project_id ],
    [ :vote_changes, :votes, :vote_id ],
    [ :vote_mfs, :projects, :project_id ],
    [ :votes, :projects, :project_1_id ],
    [ :votes, :projects, :project_2_id ],
    [ :votes, :ship_events, :ship_event_1_id ],
    [ :votes, :ship_events, :ship_event_2_id ],
    [ :ysws_review_devlog_approvals, :devlogs, :devlog_id ],
    [ :ysws_review_submissions, :projects, :project_id ]
  ].freeze

  NULLIFY = [
    [ :fraud_reports, :users, :user_id ],
    [ :fraud_reports, :users, :resolved_by_id ],
    [ :readme_certifications, :users, :reviewer_id ],
    [ :ship_certifications, :users, :reviewer_id ],
    [ :ship_certifications, :users, :ysws_returned_by_id ],
    [ :ship_reviewer_payout_requests, :users, :reviewer_id ],
    [ :ship_reviewer_payout_requests, :users, :approved_by_id ],
    [ :shop_card_grants, :users, :user_id ],
    [ :shop_orders, :users, :user_id ],
    [ :shop_warehouse_packages, :users, :user_id ],
    [ :vote_mfs, :users, :voter_id ],
    [ :votes, :users, :user_id ],
    [ :votes, :users, :marked_invalid_by_id ],
    [ :ysws_review_devlog_approvals, :users, :user_id ],
    [ :ysws_review_submissions, :users, :reviewer_id ]
  ].freeze

  def up
    CASCADE.each { |from, to, column| replace_foreign_key(from, to, column, :cascade) }
    NULLIFY.each do |from, to, column|
      change_column_null from, column, true
      replace_foreign_key(from, to, column, :nullify)
    end
    change_column_null :payouts, :user_id, true
  end

  def down
    (CASCADE + NULLIFY).each { |from, to, column| replace_foreign_key(from, to, column, nil) }
  end

  private

  def replace_foreign_key(from, to, column, on_delete)
    remove_foreign_key from, to, column: column
    add_foreign_key from, to, column: column, on_delete: on_delete, validate: false
  end
end
