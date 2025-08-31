# frozen_string_literal: true

class RefillUserVoteQueueJob < ApplicationJob
  queue_as :default
  include UniqueJob

  def perform(user_id)
    Rails.logger.info "RefillUserVoteQueueJob is deprecated"
  end
end
