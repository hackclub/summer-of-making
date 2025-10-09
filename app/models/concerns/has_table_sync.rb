# frozen_string_literal: true

module HasTableSync
  RECORD_LIMIT_PER_CALL = 10_000

  extend ActiveSupport::Concern
  included do
    class_attribute :table_syncs, default: {}

    def self.has_table_sync(sync_name, base, table, mapping, scope: nil)
      # Store sync configuration
      self.table_syncs[sync_name] = {
        base: base,
        table: table,
        mapping: mapping,
        scope: scope
      }

      # Define a method for this specific sync
      self.class.define_method("mirror_#{sync_name}_to_airtable!") do |sync_id|
        sync_config = table_syncs[sync_name]
        headers = sync_config[:mapping].keys.map(&:to_s)
        records = (sync_config[:scope] ? self.send(sync_config[:scope]) : self.all).load

        records.each_slice(RECORD_LIMIT_PER_CALL) do |chunk|
          csv = CSV.generate do |csv|
            csv << headers
            chunk.each do |record|
              row = []
              sync_config[:mapping].values.each do |field|
                row << (field.class == Symbol ? record.try(field) : record.instance_eval(&field))
              end
              csv << row
            end
          end
          url = "#{ENV["AIRTABLE_BASE_URL"] || "https://api.airtable.com"}/v0/#{sync_config[:base]}/#{sync_config[:table]}/sync/#{sync_id}"
          response = Faraday.post(url) do |req|
            req.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:airtable, :table_sync_pat)}"
            req.headers["Content-Type"] = "text/csv"
            req.body = csv
          end
          begin
            res = JSON.parse(response.body)
          rescue JSON::ParserError => e
            Honeybadger.notify("Airtable table sync JSON parse error", context: {
              model: self.name,
              sync_name: sync_name,
              url: url,
              status: response.status,
              headers: (response.respond_to?(:headers) ? response.headers : nil),
              body: response.body.to_s
            })
            raise
          end
          if res["error"]
            Honeybadger.notify("Airtable table sync API error", context: {
              model: self.name,
              sync_name: sync_name,
              url: url,
              status: response.status,
              error: res["error"],
              response: res
            })
            raise StandardError, res["error"]
          end
        end
        nil
      end

      # Define a class method to get all available sync names
      self.class.define_singleton_method(:table_sync_names) do
        table_syncs.keys
      end

      # Define a class method to get sync configuration
      self.class.define_singleton_method(:table_sync_config) do |sync_name|
        table_syncs[sync_name]
      end
    end

    # Backward compatibility method that uses the first sync if only one exists
    def self.mirror_to_airtable!(sync_id)
      if table_syncs.size == 1
        sync_name = table_syncs.keys.first
        send("mirror_#{sync_name}_to_airtable!", sync_id)
      else
        raise StandardError, "Multiple table syncs defined. Please specify which sync to use: #{table_syncs.keys.join(', ')}"
      end
    end
  end
end
