# uploads ysws_submission to the unified db airtable

class YswsReview::UploadToUnifiedDbJob < ApplicationJob
  queue_as :default

  def perform
    # First, grab 10 projects that haven't been synced yet and create them
    if new_records_to_upload.any?
      puts "Found #{new_records_to_upload.count} new records to upload"

      # Create records for the unified DB with proper field mapping
      records_to_create = new_records_to_upload.map do |record|
        unified_db_table.new(map_fields_for_unified_db(record.fields))
      end

      # Upload to unified DB
      created_records = unified_db_table.batch_create(records_to_create)

      if created_records && created_records.any?
        puts "Successfully created #{created_records.count} records in unified DB"

        # Update source records with the new record IDs
        update_source_records_with_new_ids(created_records)
      else
        puts "No records were created"
      end
    end

    # Then, find existing records to update
    if existing_records_to_update.any?
      puts "Found #{existing_records_to_update.count} existing records to update"

      # Create update records for the unified DB with proper field mapping
      records_to_update = existing_records_to_update.map do |record|
        unified_record = unified_db_table.find(record.fields["Automation - YSWS Record ID"])

        # Update the unified record with new field data
        map_fields_for_unified_db(record.fields).each do |field, value|
          unified_record[field] = value
        end

        unified_record
      end

      # Update records in unified DB
      updated_records = unified_db_table.batch_update(records_to_update)

      if updated_records && updated_records.any?
        puts "Successfully updated #{updated_records.count} records in unified DB"

        # Mark source records as processed
        mark_existing_records_as_processed
      else
        puts "No records were updated"
      end
    end
  end

  private

  def new_records_to_upload
    @new_records_to_upload ||= source_table.all(
      max_records: 10,
      filter: "AND(BLANK() = {Automation - YSWS Record ID}, upload_to_unified = TRUE())"
    )
  end

  def existing_records_to_update
    @existing_records_to_update ||= source_table.all(
      max_records: 10,
      filter: "AND(NOT(BLANK() = {Automation - YSWS Record ID}), upload_to_unified = TRUE())"
    )
  end

  def source_table
    @source_table ||= Norairrecord.table(
      ENV["UNIFIED_DB_INTEGRATION_AIRTABLE_KEY"],
      "appNF8MGrk5KKcYZx",
      "ysws_submission"
    )
  end

  def unified_db_table
    @unified_db_table ||= Norairrecord.table(
      ENV["UNIFIED_DB_INTEGRATION_AIRTABLE_KEY"],
      "app3A5kJwYqxMLOgh",
      "Approved Projects"
    )
  end

  def map_fields_for_unified_db(source_fields)
    allowed_fields = [
      "Playable URL", "Code URL", "Description", "Email", "First Name", "Last Name",
      "GitHub Username", "Address (Line 1)", "Address (Line 2)", "City",
      "State / Province", "ZIP / Postal Code", "Country", "Birthday", "Screenshot"
    ]

    mapped_fields = source_fields.select { |field, _value| allowed_fields.include?(field) }
    mapped_fields["Override Hours Spent"] = source_fields["Optional - Override Hours Spent"]
    mapped_fields["Override Hours Spent Justification"] = source_fields["Optional - Override Hours Spent Justification"]
    mapped_fields["YSWS"] = [ "recqBfqSF8s5PcVb8" ]

    # Filter Screenshot attachments to only include url and filename
    if mapped_fields["Screenshot"].is_a?(Array)
      mapped_fields["Screenshot"] = mapped_fields["Screenshot"].map do |attachment|
        { "url" => attachment["url"], "filename" => attachment["filename"] }
      end
    end

    mapped_fields
  end

  def update_source_records_with_new_ids(created_records)
    # Collect updates for batch operation
    records_to_update = []

    new_records_to_upload.each_with_index do |original_record, index|
      created_record = created_records[index]
      next unless created_record&.id

      puts "Preparing update for record with new ID: #{created_record.id}"

      # Update the original record with the new unified DB record ID
      original_record["Automation - YSWS Record ID"] = created_record.id
      original_record["upload_to_unified"] = false
      records_to_update << original_record
    end

    # Batch update all records at once
    source_table.batch_update(records_to_update) if records_to_update.any?
  end

  def mark_existing_records_as_processed
    # Collect updates for batch operation
    records_to_update = []

    existing_records_to_update.each do |original_record|
      puts "Marking record as processed: #{original_record.fields['Automation - YSWS Record ID']}"

      # Mark as no longer needing upload
      original_record["upload_to_unified"] = false
      records_to_update << original_record
    end

    # Batch update all records at once
    source_table.batch_update(records_to_update) if records_to_update.any?
  end
end
