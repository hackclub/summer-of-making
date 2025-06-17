# frozen_string_literal: true

class SyncUserToAirtableJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    return unless user

    # Use Airrecord table
    table = Airrecord.table(Rails.application.credentials.airtable.api_key,
                            Rails.application.credentials.airtable.base_id, "_users")

    # Prepare user data for Airrecord
    user_data = {
      "first_name" => user.first_name,
      "last_name" => user.last_name,
      "email" => user.email,
      "slack_id" => user.slack_id,
      "avatar_url" => user.avatar,
      "has_commented" => user.has_commented,
      "is_admin" => user.is_admin,
      "hours" => user.hackatime_stat&.total_seconds_across_all_projects&.fdiv(3600),
      # "verification_status" => user.verification_status.to_s,
      "created_at" => user.created_at
    }

    existing_record = table.all(filter: "{slack_id} = '#{user.slack_id}'").first

    if existing_record
      updated = false
      %w[first_name last_name email slack_id avatar_url has_commented is_admin hours created_at].each do |field|
        new_value = user_data[field]
        if existing_record[field] != new_value
          existing_record[field] = new_value
          updated = true
        end
      end
      existing_record.save if updated
    else
      record = table.new(user_data)
      record.save
    end
  end
end
