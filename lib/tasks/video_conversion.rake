namespace :video_conversion do
  desc "Backfill video conversions for existing ship certifications"
  task backfill: :environment do
    puts "Starting video conversion backfill..."
    BackfillVideoConversionsJob.perform_later
    puts "Backfill job queued! Check the job queue for progress."
  end

  desc "Run video conversion backfill immediately (synchronous)"
  task backfill_now: :environment do
    puts "Running video conversion backfill immediately..."
    BackfillVideoConversionsJob.perform_now
    puts "Backfill completed!"
  end

  desc "Show video conversion statistics"
  task stats: :environment do
    total = ShipCertification.joins(:proof_video_attachment).count

    web_friendly = ShipCertification.joins(:proof_video_attachment)
                                   .includes(proof_video_attachment: :blob)
                                   .select { |sc|
                                     content_type = sc.proof_video.content_type
                                     content_type&.include?("mp4") || content_type&.include?("webm")
                                   }.count

    needs_conversion = total - web_friendly

    puts "Video Conversion Statistics:"
    puts "  Total videos: #{total}"
    puts "  Already web-friendly (MP4/WebM): #{web_friendly}"
    puts "  Needs conversion: #{needs_conversion}"

    if needs_conversion > 0
      puts "\nRun 'rails video_conversion:backfill' to convert remaining videos"
    end
  end
end
