class BackfillVideoConversionsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting video conversion backfill..."

    ship_certifications = ShipCertification.joins(:proof_video_attachment)
                                          .includes(proof_video_attachment: :blob)

    total_count = ship_certifications.count
    converted_count = 0
    skipped_count = 0

    Rails.logger.info "Found #{total_count} ship certifications with videos"

    ship_certifications.find_each do |ship_cert|
      content_type = ship_cert.proof_video.content_type

      if content_type&.include?("mp4") || content_type&.include?("webm")
        Rails.logger.debug "Skipping ShipCertification #{ship_cert.id} - already web-friendly (#{content_type})"
        skipped_count += 1
        next
      end

      Rails.logger.info "Queueing conversion for ShipCertification #{ship_cert.id} (#{content_type})"
      VideoConversionJob.perform_unique(ship_cert.id)
      converted_count += 1

      sleep(0.1)
    end

    Rails.logger.info "Video conversion backfill completed:"
    Rails.logger.info "  Total videos found: #{total_count}"
    Rails.logger.info "  Queued for conversion: #{converted_count}"
    Rails.logger.info "  Skipped (already web-friendly): #{skipped_count}"
  end
end
