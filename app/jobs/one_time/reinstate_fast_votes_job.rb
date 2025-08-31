class OneTime::ReinstateFastVotesJob < ApplicationJob
  queue_as :default

  # have to do this because analytics were borked for a while
  #   OneTime::ReinstateFastVotesJob.perform_now(
  #     start_date: "2025-07-20",
  #     end_date: "2025-08-03",
  #     dry_run: false
  #   )
  def perform(start_date: nil, end_date: nil, dry_run: false)
    start_at = start_date.present? ? Time.zone.parse(start_date.to_s).beginning_of_day : nil
    end_at   = end_date.present? ? Time.zone.parse(end_date.to_s).end_of_day : nil

    scope = Vote.where(status: "invalid", invalid_reason: "too_fast_under_30s")
    scope = scope.where(created_at: start_at..end_at) if start_at && end_at

    count = scope.count
    Rails.logger.info "Found #{count} votes invalidated for too_fast_under_30s#{start_at && end_at ? " between #{start_at} and #{end_at}" : ""}"

    return if count.zero?

    updates = {
      status: "active",
      invalid_reason: nil,
      marked_invalid_at: nil,
      marked_invalid_by_id: nil
    }
    updates[:is_low_quality] = false if Vote.column_names.include?("is_low_quality")

    if dry_run
      Rails.logger.info "[dry-run] Would reinstate #{count} votes"
    else
      affected = scope.update_all(updates)
      Rails.logger.info "Reinstated #{affected} votes"
    end
  end
end
