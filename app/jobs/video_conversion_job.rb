# frozen_string_literal: true

# Retain the class for jobs queued before the archive stopped processing uploads.
class VideoConversionJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  def self.perform_unique(ship_certification_id)
    perform_unique_with_args(ship_certification_id)
  end

  def perform(_ship_certification_id)
    Rails.logger.info "Video conversion is disabled for the Summer of Making archive"
  end
end
