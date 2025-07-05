#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# Airtable API setup
API_KEY = ENV['HIGHSEAS_INTEGRATION_AIRTABLE_KEY']
BASE_ID = 'appTeNFYcUiYfGcR6'
BASE_URL = "https://api.airtable.com/v0/#{BASE_ID}"

puts "Exploring Airtable schema..."
puts "Base ID: #{BASE_ID}"
puts "API Key present: #{!API_KEY.nil? && !API_KEY.empty?}"

# First, get the base schema
def get_base_schema
  uri = URI("https://api.airtable.com/v0/meta/bases/#{BASE_ID}/tables")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{API_KEY}"
  
  response = http.request(request)
  JSON.parse(response.body)
end

# Get sample records from a table
def get_sample_records(table_name, limit = 3)
  uri = URI("#{BASE_URL}/#{URI.encode_www_form_component(table_name)}?maxRecords=#{limit}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{API_KEY}"
  
  response = http.request(request)
  JSON.parse(response.body)
end

# Main execution
begin
  schema = get_base_schema
  
  puts "\n" + "="*60
  puts "AIRTABLE SCHEMA EXPLORATION"
  puts "="*60
  
  puts "Available tables:"
  schema['tables'].each do |table|
    puts "- #{table['name']} (#{table['id']})"
  end
  
  puts "\nDetailed schema:"
  schema['tables'].each do |table|
    puts "\nTable: #{table['name']}"
    puts "ID: #{table['id']}"
    puts "Fields:"
    
    table['fields'].each do |field|
      puts "  - #{field['name']} (#{field['type']})"
      if field['options']
        puts "    Options: #{field['options'].inspect}"
      end
    end
    
    # Get sample records
    puts "\nSample records:"
    begin
      sample = get_sample_records(table['name'])
      sample['records'].each_with_index do |record, i|
        puts "  Record #{i+1}:"
        record['fields'].each do |field_name, value|
          puts "    #{field_name}: #{value.inspect}"
        end
      end
    rescue => e
      puts "  Error getting sample records: #{e.message}"
    end
    
    puts "\n" + "-"*40
  end
  
rescue => e
  puts "Error: #{e.message}"
  puts "Make sure HIGHSEAS_INTEGRATION_AIRTABLE_KEY is set"
end
