class BackfillShipFeedbackJob < ApplicationJob
  queue_as :default
  
  BATCH_SIZE = 10 

  def perform(batch_start_id = nil)
    # Only process ship events that have payouts but no feedback
    ship_events = ShipEvent.joins(:payouts)
                          .where(feedback: [nil, ""])
                          .order(:id)

    ship_events = ship_events.where("id >= ?", batch_start_id) if batch_start_id
    ship_events = ship_events.limit(BATCH_SIZE)

    processed_count = 0
    failed_count = 0
    last_processed_id = batch_start_id

    ship_events.find_each do |ship_event|
      last_processed_id = ship_event.id
      
      begin
        service = ShipFeedbackService.new(ship_event)
        feedback = service.generate_feedback
        
        if feedback.present?
          processed_count += 1
        else
          failed_count += 1
        end
        
        sleep(2)
        
      rescue => e
        Rails.logger.error "Error generating feedback for ship_event #{ship_event.id}: #{e.message}"
        failed_count += 1
      end
    end

    remaining_count = ShipEvent.joins(:payouts)
                               .where(feedback: [nil, ""])
                               .where("id > ?", last_processed_id || 0)
                               .count

    if remaining_count > 0
      Rails.logger.info "Queueing next batch starting from ID #{last_processed_id + 1}. #{remaining_count} ship events remaining."
      BackfillShipFeedbackJob.set(wait: 30.seconds).perform_later(last_processed_id + 1)
    else
      Rails.logger.info "Backfill complete! Processed #{processed_count} ship events in this batch."
    end
  end
end