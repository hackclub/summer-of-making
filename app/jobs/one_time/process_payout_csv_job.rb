class OneTime::ProcessPayoutCsvJob < ApplicationJob
  queue_as :default

  def perform(csv_source, force_proceed = false)
    require "csv"
    require "net/http"
    require "uri"

    # Auto-detect source type
    source_type = detect_source_type(csv_source)

    puts "🔍 Detected source type: #{source_type}"

    # Fetch CSV data based on source type
    csv_data = fetch_csv_data(csv_source, source_type)

    # Parse CSV data
    csv_rows = CSV.parse(csv_data, headers: false)

    puts "📊 Found #{csv_rows.count} rows in CSV"
    puts "🔍 First few rows for debugging:"
    csv_rows.first(5).each_with_index do |row, i|
      puts "  Row #{i}: #{row.inspect}"
    end
    puts "---"

    # Phase 1: Validate and identify issues
    puts "🔍 Starting validation..."
    validation_result = validate_csv_data(csv_rows)

    # Print validation summary
    puts ""
    puts "📋 VALIDATION SUMMARY:"
    puts "  ✅ Valid rows: #{validation_result[:valid_rows].count}"
    puts "  ❌ Critical errors: #{validation_result[:critical_errors].count}"
    puts "  ⚠️  Missing users: #{validation_result[:missing_users].count}"
    puts ""

    if validation_result[:critical_errors].any?
      puts "🚨 CRITICAL VALIDATION ERRORS FOUND:"
      validation_result[:critical_errors].each_with_index do |error, index|
        puts "  #{index + 1}. #{error}"
      end
      puts ""
      puts "❌ Aborting payout processing due to critical errors."
      raise StandardError, "CSV validation failed with #{validation_result[:critical_errors].count} critical errors"
    end

    # Check for missing users
    if validation_result[:missing_users].any? && !force_proceed
      puts "⚠️  MISSING USERS DETECTED:"
      validation_result[:missing_users].each_with_index do |missing, index|
        puts "  #{index + 1}. Slack ID: #{missing[:slack_id]} | Amount: $#{missing[:amount]} | Reason: #{missing[:reason]}"
      end
      puts ""
      puts "💰 Total amount for missing users: $#{validation_result[:missing_users].sum { |u| u[:amount] }}"
      puts ""
      puts "💡 To proceed with only valid users, run with force_proceed: true"
      raise StandardError, "Missing users detected. Set force_proceed: true to continue with valid users only."
    end

    # Phase 2: Process only valid users
    valid_rows = validation_result[:valid_rows]

    if valid_rows.empty?
      puts "⚠️  No valid rows to process"
      return { processed_count: 0, error_count: 0, errors: [], missing_users: validation_result[:missing_users] }
    end

    puts "🚀 Proceeding with #{valid_rows.count} valid users..."
    puts ""

    # Process all payouts in a single transaction
    processed_count = 0

    ActiveRecord::Base.transaction do
      valid_rows.each_with_index do |row_data, index|
        slack_id = row_data[:slack_id]
        amount = row_data[:amount]
        reason = row_data[:reason]
        user = row_data[:user]

        # Create payout
        payout = Payout.create!(
          user: user,
          amount: amount,
          reason: reason,
          payable: user
        )

        processed_count += 1
        puts "✅ #{index + 1}/#{valid_rows.count}: Created payout $#{amount} for #{user.display_name} (#{slack_id}) - #{reason}"
      end
    end

    puts ""
    puts "🎉 PAYOUT PROCESSING COMPLETED SUCCESSFULLY!"
    puts "  📊 Total payouts created: #{processed_count}"
    puts "  💰 Total amount processed: $#{valid_rows.sum { |r| r[:amount] }}"

    if validation_result[:missing_users].any?
      puts "  ⚠️  Skipped users: #{validation_result[:missing_users].count}"
      puts "  💰 Skipped amount: $#{validation_result[:missing_users].sum { |u| u[:amount] }}"
    end

    # Return results for potential use by caller
    {
      processed_count: processed_count,
      error_count: 0,
      errors: [],
      missing_users: validation_result[:missing_users],
      skipped_count: validation_result[:missing_users].count
    }

  rescue StandardError => e
    puts ""
    puts "💥 PAYOUT PROCESSING FAILED:"
    puts "  Error: #{e.message}"
    puts "  Backtrace: #{e.backtrace.first(5).join("\n    ")}"
    Rails.logger.error "Payout processing failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  private

  def detect_source_type(source)
    return :data if source.is_a?(String) && source.include?("\n") && source.include?(",")
    return :url if source.is_a?(String) && (source.start_with?("http://", "https://") || source.match?(/^https?:\/\//))
    return :file if source.is_a?(String) && File.exist?(source)
    :data # Default to treating as raw CSV data
  end

  def fetch_csv_data(source, source_type)
    case source_type.to_sym
    when :file
      unless File.exist?(source)
        raise StandardError, "CSV file not found: #{source}"
      end
      File.read(source)

    when :url
      puts "🌐 Fetching CSV from URL: #{source}"
      uri = URI.parse(source)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, "Failed to fetch CSV from URL: #{response.code} #{response.message}"
      end

      # Fix encoding issues by forcing UTF-8
      csv_body = response.body.force_encoding("UTF-8")

      puts "✅ Successfully fetched CSV data (#{csv_body.length} characters)"
      csv_body

    when :data
      # Assume source is already CSV data
      source

    else
      raise StandardError, "Invalid source type: #{source_type}. Must be :file, :url, or :data"
    end
  end

  def validate_csv_data(csv_rows)
    critical_errors = []
    missing_users = []
    valid_rows = []

    puts "🔍 Validating #{csv_rows.count} rows..."

    csv_rows.each_with_index do |row, index|
      slack_id = row[0]&.strip
      amount_str = row[1]&.strip

      # Skip empty rows
      if slack_id.blank? && amount_str.blank?
        puts "  ⏭️  Row #{index + 1}: Skipping empty row"
        next
      end

      # Check for required fields
      if slack_id.blank?
        error_msg = "Row #{index + 1}: Missing slack_id"
        puts "  ❌ #{error_msg}"
        critical_errors << error_msg
        next
      end

      if amount_str.blank?
        error_msg = "Row #{index + 1}: Missing amount for Slack ID '#{slack_id}'"
        puts "  ❌ #{error_msg}"
        critical_errors << error_msg
        next
      end

      # Validate amount format
      begin
        # Handle both integer and decimal amounts
        amount = parse_amount(amount_str)
        if amount <= 0
          error_msg = "Row #{index + 1}: Amount must be positive for Slack ID '#{slack_id}'"
          puts "  ❌ #{error_msg}"
          critical_errors << error_msg
          next
        end
      rescue ArgumentError, TypeError => e
        error_msg = "Row #{index + 1}: Invalid amount format '#{amount_str}' for Slack ID '#{slack_id}': #{e.message}"
        puts "  ❌ #{error_msg}"
        critical_errors << error_msg
        next
      end

      # Validate user exists
      user = User.find_by(slack_id: slack_id)
      if user.nil?
        missing_user_info = { slack_id: slack_id, amount: amount, reason: sanitize_reason(row[2]) }
        missing_users << missing_user_info
        puts "  ⚠️  Row #{index + 1}: User not found with Slack ID '#{slack_id}' (Amount: $#{amount})"
      else
        valid_row_data = {
          slack_id: slack_id,
          amount: amount,
          reason: sanitize_reason(row[2]),
          user: user
        }
        valid_rows << valid_row_data
        puts "  ✅ Row #{index + 1}: Valid - #{user.display_name} (#{slack_id}) - $#{amount}"
      end
    end

    {
      critical_errors: critical_errors,
      missing_users: missing_users,
      valid_rows: valid_rows
    }
  end

  def generate_missing_users_message(missing_users)
    message = "The following users were not found in the database:\n"
    missing_users.each do |missing|
      message += "  - Slack ID: #{missing[:slack_id]}, Amount: $#{missing[:amount]}, Reason: #{missing[:reason]}\n"
    end
    message += "\nTotal missing users: #{missing_users.count}"
    message += "\nTotal amount for missing users: $#{missing_users.sum { |u| u[:amount] }}"
    message
  end

  def parse_amount(amount_str)
    return nil if amount_str.nil? || amount_str.strip.empty?

    # Remove any currency symbols and whitespace
    cleaned_amount = amount_str.strip.gsub(/[$,\s]/, "")

    # Handle both integer and decimal formats
    if cleaned_amount.match?(/^\d+$/)
      # Integer format (e.g., "100")
      BigDecimal(cleaned_amount)
    elsif cleaned_amount.match?(/^\d+\.\d+$/)
      # Decimal format (e.g., "100.50")
      BigDecimal(cleaned_amount)
    elsif cleaned_amount.match?(/^\d+\.$/)
      # Decimal with no cents (e.g., "100.")
      BigDecimal(cleaned_amount + "0")
    else
      raise ArgumentError, "Invalid amount format: #{amount_str}"
    end
  end

  def sanitize_reason(reason)
    return "Manual payout from CSV" if reason.blank?

    # Remove any non-ASCII characters and normalize
    sanitized = reason.strip
      .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      .gsub(/[^\x20-\x7E]/, "") # Keep only printable ASCII characters
      .strip

    # Fallback if everything was removed
    sanitized.present? ? sanitized : "Manual payout from CSV"
  end
end
