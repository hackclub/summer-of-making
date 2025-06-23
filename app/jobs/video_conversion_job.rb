class VideoConversionJob < ApplicationJob
  queue_as :video_conversion

  def self.perform_unique(ship_certification_id)
    return if SolidQueue::Job.where(
      queue_name: "video_conversion",
      class_name: "VideoConversionJob"
    ).pending.any? { |job| job.arguments.first == ship_certification_id }

    perform_later(ship_certification_id)
  end

  def perform(ship_certification_id)
    ship_certification = ShipCertification.find(ship_certification_id)
    return unless ship_certification.proof_video.attached?

    Rails.logger.info "Starting video conversion for ShipCertification #{ship_certification_id}"

    # Download the original video to a temporary file
    ship_certification.proof_video.open do |original_file|
      # Create a temporary file for the converted video
      converted_file = Tempfile.new([ "converted_video", ".mp4" ])

      begin
        convert_video(original_file.path, converted_file.path)

        ship_certification.proof_video.attach(
          io: File.open(converted_file.path),
          filename: "#{ship_certification.proof_video.filename.base}.mp4",
          content_type: "video/mp4"
        )

        Rails.logger.info "Video conversion completed for ShipCertification #{ship_certification_id}"

      rescue => e
        Rails.logger.error "Video conversion failed for ShipCertification #{ship_certification_id}: #{e.message}"
        raise e
      ensure
        converted_file.close
        converted_file.unlink
      end
    end
  end

  private

  def convert_video(input_path, output_path)
    require "streamio-ffmpeg"

    FFMPEG.ffmpeg_binary = "/usr/bin/ffmpeg"
    FFMPEG.ffprobe_binary = "/usr/bin/ffprobe"

    movie = FFMPEG::Movie.new(input_path)

    options = {
      video_codec: "libx264",
      audio_codec: "aac",
      video_bitrate: "1000k",
      audio_bitrate: "128k",
      resolution: "1280x720",      # Max 720p for web
      frame_rate: 30,
      custom: [
        "-preset", "medium",       # Good balance of speed vs quality
        "-crf", "23",              # Good quality setting
        "-movflags", "+faststart", # Enable progressive download
        "-pix_fmt", "yuv420p"      # Ensure compatibility
      ]
    }

    if movie.width && movie.height
      if movie.width <= 1280 && movie.height <= 720
        options.delete(:resolution)
      end
    end

    movie.transcode(output_path, options)
  end
end
