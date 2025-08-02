class AirtableSyncJob < ApplicationJob
  queue_as :literally_whenever

  def perform(syncable_type = "Project", limit = 10, specific_sync_records = nil)
    model_class = syncable_type.constantize

    if specific_sync_records
      sync_records = specific_sync_records
    else
      sync_records = AirtableSync.where(syncable_type: syncable_type).includes(:syncable).oldest_synced.limit(limit)

      if sync_records.empty?
        records = model_class.limit(limit)
        records.find_each do |record|
          record.create_airtable_sync!
        end
        sync_records = AirtableSync.where(syncable_type: syncable_type).includes(:syncable).oldest_synced.limit(limit)
      end
    end

    airtable_data = sync_records.map do |sync_record|
      record = sync_record.syncable
      # Use the instance method airtable_mapped_data for dynamic field mappings
      mapped_data = record.airtable_mapped_data

      {
        sync_record: sync_record,
        airtable_data: mapped_data
      }
    end

    table = Norairrecord.table(
      Rails.application.credentials.airtable.api_key,
      Rails.application.credentials.airtable.base_id,
      model_class.airtable_table_name
    )

    records = airtable_data.map do |data|
      table.new(data[:airtable_data].merge("som_id" => data[:sync_record].syncable.id.to_s))
    end

    Rails.logger.info "About to batch_upsert #{records.count} records"
    Rails.logger.info "Sample record data: #{records.first&.fields&.inspect}"

    upserted_records = table.batch_upsert(records, "som_id")

    Rails.logger.info "Batch upsert response: #{upserted_records.inspect}"

    airtable_records = upserted_records[:records] || []

    Rails.logger.info "Found #{airtable_records.count} records in response"
    if upserted_records[:errors]&.any?
      Rails.logger.error "Batch upsert errors: #{upserted_records[:errors].inspect}"
    end

    sync_records.each do |sync_record|
      airtable_record = airtable_records.find do |record|
        record["fields"]["som_id"] == sync_record.syncable.id.to_s
      end

      if airtable_record
        sync_record.update!(
          airtable_record_id: airtable_record["id"],
          last_synced_at: Time.current
        )
        Rails.logger.info "Updated sync #{sync_record.id} with Airtable ID: #{airtable_record['id']}"
      else
        Rails.logger.warn "Could not find Airtable record for sync #{sync_record.id}"
        sync_record.mark_synced!
      end
    end
  end
end
