class YswsReview::SyncSubmissionJob < ApplicationJob
  queue_as :latency_5m

  def perform(submission_id)
    submission = YswsReview::Submission.find(submission_id)

    # Ensure the project is synced to Airtable first
    ensure_project_synced!(submission.project)

    # Ensure the submission has an airtable_sync record
    sync_record = submission.ensure_airtable_sync!

    if submission.is_initial_sync?
      Rails.logger.info "Performing initial YSWS submission sync for project #{submission.project.id} (includes photo upload)"
    else
      Rails.logger.info "Performing update YSWS submission sync for project #{submission.project.id} (data only)"
    end

    # Log the data being sent to Airtable for debugging
    mapped_data = submission.airtable_mapped_data
    Rails.logger.info "Data being sent to Airtable: #{mapped_data.inspect}"

    # Use the standard AirtableSyncJob to test if batch_upsert now works with "project" field
    AirtableSyncJob.perform_now("YswsReview::Submission", 1, [ sync_record ])

    Rails.logger.info "YSWS submission sync completed for project #{submission.project.id}"
  rescue => e
    Rails.logger.error "YSWS submission sync failed for project #{submission.project.id}: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    raise e
  end

  private

  def sync_submission_hybrid(submission, sync_record, mapped_data)
    # Separate linked fields from regular fields
    linked_fields = mapped_data.select { |field, value| field.start_with?("_") }
    regular_fields = mapped_data.reject { |field, value| field.start_with?("_") }

    Rails.logger.info "Regular fields: #{regular_fields.keys}"
    Rails.logger.info "Linked fields: #{linked_fields.keys}"

    # Use batch_upsert for regular fields (efficient)
    if regular_fields.any?
      Rails.logger.info "Syncing regular fields via batch_upsert"
      AirtableSyncJob.perform_now("YswsReview::Submission", 1, [ sync_record ])
    end

    # Use direct update for linked fields (reliable)
    if linked_fields.any?
      Rails.logger.info "Updating linked fields directly"
      table = Norairrecord.table(
        Rails.application.credentials.airtable.api_key,
        Rails.application.credentials.airtable.base_id,
        submission.airtable_table_name
      )

      existing_record = table.find(sync_record.airtable_record_id)
      linked_fields.each do |field, value|
        Rails.logger.info "Setting linked field #{field} = #{value.inspect}"
        existing_record[field] = value
      end
      existing_record.save

      Rails.logger.info "Successfully updated linked fields"
    end

    sync_record.mark_synced!
  end

  def ensure_project_synced!(project)
    return if project.airtable_synced?

    Rails.logger.info "Project #{project.id} not synced to Airtable yet, syncing now..."

    # Ensure project has an airtable_sync record and sync it
    project_sync_record = project.ensure_airtable_sync!
    AirtableSyncJob.perform_now("Project", 1, [ project_sync_record ])

    Rails.logger.info "Project #{project.id} synced to Airtable"
  end
end
