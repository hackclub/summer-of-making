# frozen_string_literal: true

class RefillUserVoteQueueJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    vote_queue = user.user_vote_queue || user.build_user_vote_queue.tap(&:save!)

    # Refill if needed
    if vote_queue.needs_refill? || vote_queue.queue_exhausted?
      generated_count = vote_queue.refill_queue!
      Rails.logger.info "Refilled vote queue for user #{user_id}: #{generated_count} new matchups"
    end
  rescue => e
    Rails.logger.error "Failed to refill vote queue for user #{user_id}: #{e.message}"
    raise e
  end
end
