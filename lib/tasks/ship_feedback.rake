namespace :ship_feedback do
  desc "Backfill AI feedback for existing ship events that have payouts"
  task backfill: :environment do
    total_count = ShipEvent.joins(:payouts).where(feedback: [nil, ""]).count
    
    puts "Starting backfill for #{total_count} ship events without feedback..."

    if total_count > 0
      BackfillShipFeedbackJob.perform_later
    else
      puts "No ship events need feedback backfill!"
    end
  end

  desc "Check progress of feedback backfill"
  task status: :environment do
    total_with_payouts = ShipEvent.joins(:payouts).count
    with_feedback = ShipEvent.joins(:payouts).where.not(feedback: [nil, ""]).count
    without_feedback = total_with_payouts - with_feedback
    
    percentage = total_with_payouts > 0 ? (with_feedback.to_f / total_with_payouts * 100).round(1) : 0
    
    puts "Ship Feedback stats:"
    puts "  Total ship events with payouts: #{total_with_payouts}"
    puts "  With AI feedback: #{with_feedback} (#{percentage}%)"
    puts "  Without feedback: #{without_feedback}"
  end

end