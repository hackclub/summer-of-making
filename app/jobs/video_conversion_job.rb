class VideoConversionJob < ApplicationJob
  include UniqueJob

  queue_as :literally_whenever

  def self.perform_unique(ship_certification_id)
    perform_unique_with_args(ship_certification_id)
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
        Honeybadger.notify(e, context: { ship_certification_id: ship_certification_id })
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
      custom: [
        "-preset", "medium",       # Good balance of speed vs quality
        "-crf", "23",              # Good quality setting
        "-movflags", "+faststart", # Enable progressive download
        "-pix_fmt", "yuv420p",     # Ensure compatibility
        "-vf", "scale='min(1280,iw)':'min(720,ih)':force_original_aspect_ratio=decrease,scale=trunc(iw/2)*2:trunc(ih/2)*2"
      ]
    }

    movie.transcode(output_path, options)
  end
end
