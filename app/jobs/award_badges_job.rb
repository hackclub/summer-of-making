class AwardBadgesJob < ApplicationJob
  queue_as :default

  def perform(user_id, trigger_event = nil, backfill = false)
    user = User.find(user_id)

    backfill_msg = backfill ? " (backfill)" : ""
    Rails.logger.info("Awarding badges for user #{user.id} (#{user.display_name}) - trigger: #{trigger_event}#{backfill_msg}")

    newly_earned = Badge.award_badges_for(user, backfill: backfill)

    if newly_earned.any?
      Rails.logger.info("User #{user.id} earned new badges: #{newly_earned.join(', ')}#{backfill_msg}")
    else
      Rails.logger.info("User #{user.id} - no new badges earned#{backfill_msg}")
    end

    newly_earned
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("User not found for badge awarding: #{e.message}")
    raise
  rescue => e
    Rails.logger.error("Error awarding badges for user #{user_id}: #{e.message}")
    Honeybadger.notify(e, context: { user_id: user_id, trigger_event: trigger_event, backfill: backfill })
    raise
  end
end
