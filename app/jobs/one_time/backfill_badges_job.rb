class OneTime::BackfillBadgesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting badge backfill job...")

    users_processed = 0
    badges_awarded = 0

    User.find_each do |user|
      # First, handle blue check to verified badge transition
      if user.shenanigans_state["blue_check"] == true && !user.has_badge?(:verified)
        user.user_badges.create!(
          badge_key: :verified,
          earned_at: Time.current
        )
        badges_awarded += 1
        Rails.logger.info("User #{user.id} (#{user.display_name}) awarded verified badge from blue_check flag")

        # Send backfill notification
        badge_definition = Badge.find(:verified)
        Badge.send_badge_notification(user, :verified, badge_definition, backfill: true)
      end

      # Then run normal badge awarding logic
      newly_earned = user.award_badges!(backfill: true)

      users_processed += 1
      badges_awarded += newly_earned.count

      if newly_earned.any?
        Rails.logger.info("User #{user.id} (#{user.display_name}) earned badges during backfill: #{newly_earned.join(', ')}")
      end

      # Log progress every 100 users
      if users_processed % 100 == 0
        Rails.logger.info("Processed #{users_processed} users so far...")
      end
    end

    Rails.logger.info("Badge backfill complete! Processed #{users_processed} users and awarded #{badges_awarded} badges.")
  end
end
