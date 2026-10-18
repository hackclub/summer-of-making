# frozen_string_literal: true

# Retain the class so previously queued jobs can complete without generating media.
class GenerateStonkNewsVideoJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*_args)
    Rails.logger.info "Video generation is disabled for the Summer of Making archive"
  end
end
