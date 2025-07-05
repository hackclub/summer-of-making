#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'csv'
require 'uri'
require 'fileutils'

# Airtable API setup
API_KEY = ENV['HIGHSEAS_INTEGRATION_AIRTABLE_KEY']
BASE_ID = 'appTeNFYcUiYfGcR6'
BASE_URL = "https://api.airtable.com/v0/#{BASE_ID}"

# Create CSV directory
FileUtils.mkdir_p('csv_data')

# Tables to download
TABLES = [
  'people',
  'ships', 
  'ship_chains',
  'battles',
  'contests',
  'shop_items',
  'shop_orders',
  'shop_addresses',
  'events',
  'doubloon_adjustments',
  'YSWS Verification',
  'ysws_submission',
  'flagged_projects',
  'shop_msr_costs',
  'sticky_holidays',
  'taverns',
  'special_prize_nominations',
  'synced_unified_ysws_high_seas',
  'shop_card_grants'
]

def download_table(table_name)
  puts "Downloading #{table_name}..."
  
  all_records = []
  offset = nil
  
  loop do
    url = "#{BASE_URL}/#{URI.encode_www_form_component(table_name)}"
    url += "?offset=#{offset}" if offset
    
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{API_KEY}"
    
    response = http.request(request)
    data = JSON.parse(response.body)
    
    if data['error']
      puts "Error downloading #{table_name}: #{data['error']['message']}"
      return
    end
    
    all_records.concat(data['records'])
    
    offset = data['offset']
    break unless offset
    
    puts "  Downloaded #{all_records.length} records so far..."
  end
  
  # Write to CSV
  csv_file = "csv_data/#{table_name}.csv"
  
  if all_records.empty?
    puts "No records found for #{table_name}"
    return
  end
  
  # Get all possible field names
  all_fields = all_records.flat_map { |record| record['fields'].keys }.uniq.sort
  
  CSV.open(csv_file, 'w') do |csv|
    # Header row
    csv << ['record_id'] + all_fields
    
    # Data rows
    all_records.each do |record|
      row = [record['id']]
      all_fields.each do |field|
        value = record['fields'][field]
        # Convert arrays and hashes to JSON strings
        if value.is_a?(Array) || value.is_a?(Hash)
          row << JSON.generate(value)
        else
          row << value
        end
      end
      csv << row
    end
  end
  
  puts "  Saved #{all_records.length} records to #{csv_file}"
end

# Download all tables
TABLES.each { |table| download_table(table) }

puts "\nDownload complete! Files saved to csv_data/ directory"
