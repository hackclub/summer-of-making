#!/usr/bin/env ruby

require_relative '../config/environment'
require 'csv'
require 'json'
require 'fileutils'

# Show usage help
if ARGV.include?('--help') || ARGV.include?('-h')
  puts "Usage: ruby script/subset_import.rb [options]"
  puts ""
  puts "Options:"
  puts "  --full, --all     Import ALL users (default: 10 users)"
  puts "  --dry-run         Show what would be imported without doing it"
  puts "  --verbose, -v     Show all operations (default: only errors/skipped)"
  puts "  --help, -h        Show this help message"
  exit
end

puts "Subset import starting..."

# Parse command line arguments
FULL_IMPORT = ARGV.include?('--full') || ARGV.include?('--all')
DRY_RUN = ARGV.include?('--dry-run')
VERBOSE = ARGV.include?('--verbose') || ARGV.include?('-v')

# Configuration
SUBSET_SIZE = FULL_IMPORT ? Float::INFINITY : 10  # Default 10 users, or all users for full import

# Storage for CSV data and mappings
@people_data = []
@ship_chains_data = []
@ships_data = []
@battles_data = []

# Mapping tables
@slack_id_to_user = {}
@record_id_to_project = {}
@record_id_to_ship_event = {}

puts "Loading CSV data into memory..." if VERBOSE

# Load all CSV data
CSV.foreach('csv_data/people.csv', headers: true) do |row|
  @people_data << row.to_h
end

CSV.foreach('csv_data/ship_chains.csv', headers: true) do |row|
  @ship_chains_data << row.to_h
end

CSV.foreach('csv_data/ships.csv', headers: true) do |row|
  @ships_data << row.to_h
end

CSV.foreach('csv_data/battles.csv', headers: true) do |row|
  @battles_data << row.to_h
end

puts "Loaded #{@people_data.size} people, #{@ship_chains_data.size} ship chains, #{@ships_data.size} ships, #{@battles_data.size} battles" if VERBOSE

# Select subset of users - let's pick users who have both ships and battles
def select_subset_users
  puts "\nSelecting subset of users..." if VERBOSE

  # First, find people with valid slack IDs (start with U and are 11 characters)
  valid_slack_people = @people_data.select { |person| person['slack_id'] && person['slack_id'].match?(/^U[A-Z0-9]{10}$/) }
  puts "Found #{valid_slack_people.size} people with valid Slack IDs" if VERBOSE

  if valid_slack_people.empty?
    puts "No people with valid Slack IDs found. Let me try a different approach..."
    # Try with identifier field instead
    people_with_identifier = @people_data.select { |person| person['identifier'] && person['identifier'].length > 0 }
    puts "Found #{people_with_identifier.size} people with identifiers"

    # Just take the first 10 people for testing
    # selected_people = people_with_identifier.first(SUBSET_SIZE)
    selected_people = people_with_identifier
    selected_users = selected_people.map { |person| person['identifier'] }
    puts "Selected #{selected_users.size} users by identifier: #{selected_users.join(', ')}"
    return selected_users
  end

  valid_slack_ids = valid_slack_people.map { |person| person['slack_id'] }
  valid_autonumbers = valid_slack_people.map { |person| person['autonumber'] }

  # Find users who have ships (projects) - extract record IDs from JSON arrays
  ship_entrant_record_ids = @ships_data.map { |ship|
    ship['entrant__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
  }.compact.uniq

  # Map record IDs to slack IDs
  users_with_ships = ship_entrant_record_ids.map { |record_id|
    person = @people_data.find { |p| p['record_id'] == record_id }
    person&.dig('slack_id') if person && valid_slack_ids.include?(person['slack_id'])
  }.compact.uniq

  # Find users who have participated in battles - extract record IDs from JSON arrays
  battle_voter_record_ids = @battles_data.map { |battle|
    battle['voter__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
  }.compact.uniq

  # Map record IDs to slack IDs
  users_with_battles = battle_voter_record_ids.map { |record_id|
    person = @people_data.find { |p| p['record_id'] == record_id }
    person&.dig('slack_id') if person && valid_slack_ids.include?(person['slack_id'])
  }.compact.uniq

  # Find users who have both ships and battles
  active_users = users_with_ships & users_with_battles

  puts "Found #{active_users.size} users with both ships and battles"

  if active_users.empty?
    puts "No users with both ships and battles. Taking #{SUBSET_SIZE == Float::INFINITY ? 'all' : "first #{SUBSET_SIZE}"} users with ships..."
    selected_users = SUBSET_SIZE == Float::INFINITY ? users_with_ships : users_with_ships.first(SUBSET_SIZE)
  else
    selected_users = SUBSET_SIZE == Float::INFINITY ? active_users : active_users.first(SUBSET_SIZE)
  end

  puts "Selected #{selected_users.size} users for import: #{selected_users.join(', ')}" if VERBOSE

  selected_users
end

def import_users(selected_slack_ids)
  puts "\n=== Importing Users ===" if VERBOSE

  puts "Looking for users with slack_ids: #{selected_slack_ids.join(', ')}" if VERBOSE

  selected_people = @people_data.select { |person| selected_slack_ids.include?(person['slack_id']) }

  puts "Found #{selected_people.size} matching people records" if VERBOSE
  puts "Importing #{selected_people.size} users..." if VERBOSE

  selected_people.each do |person|
    puts "Processing person: #{person['slack_id']} / #{person['identifier']}" if VERBOSE

    next unless person['slack_id']

    slack_id = person['slack_id']
    puts "Creating user for slack_id: #{slack_id}" if VERBOSE

    if DRY_RUN
      puts "DRY RUN: Would create user with slack_id: #{slack_id}" if VERBOSE
      next
    end

    user = User.find_or_initialize_by(slack_id: slack_id)
    if user.persisted?
      puts "User already exists: #{slack_id}" if VERBOSE
      @slack_id_to_user[slack_id] = user
      next
    end

    user.assign_attributes(
      display_name: person['identifier'] || "User #{slack_id}",
      email: person['email']&.strip || "#{person['identifier'] || slack_id}@example.com",
      timezone: 'UTC',
      avatar: 'https://placehold.co/400',
      permissions: [],
      created_at: person['created_at'] ? Time.parse(person['created_at']) : Time.current
    )

    begin
      if user.save
        @slack_id_to_user[slack_id] = user
        puts "✓ Created user: #{user.display_name} (#{slack_id})" if VERBOSE
      else
        puts "✗ Failed to create user #{slack_id}: #{user.errors.full_messages.join(', ')}"
      end
    rescue => e
      puts "✗ Exception creating user #{slack_id}: #{e.message}"
    end
  end

  puts "Users imported: #{@slack_id_to_user.size}" if VERBOSE
end

# Helper method to ensure valid URLs
def valid_url(url)
  return "https://example.com" if url.blank?

  # If URL doesn't start with http:// or https://, add https://
  url = "https://#{url}" unless url.match?(/^https?:\/\//)

  # Basic URL validation - just check if it looks like a URL
  return url if url.match?(/^https?:\/\/.+/)

  # Fallback to example.com
  "https://example.com"
end

# Helper method to extract string from JSON array fields
def extract_string_from_json_array(field)
  return "Untitled" if field.blank?

  # If it's already a string and not a JSON array, return it
  return field unless field.include?('[')

  begin
    # Parse the JSON array and get the first element
    parsed = JSON.parse(field)
    return parsed.first if parsed.is_a?(Array) && parsed.any?
  rescue JSON::ParserError
    # If JSON parsing fails, try to extract manually
    # Handle cases like ["Some Title"]
    match = field.match(/\["([^"]+)"\]/)
    return match[1] if match
  end

  # Fallback
  field
end

def import_projects(selected_slack_ids)
  puts "\n=== Importing Projects ===" if VERBOSE

  # Find ship chains for our selected users - need to match via ships first
  # Get people records for selected slack IDs
  selected_people_records = @people_data.select { |person| selected_slack_ids.include?(person['slack_id']) }
  selected_people_record_ids = selected_people_records.map { |person| person['record_id'] }

  selected_ships = @ships_data.select { |ship|
    entrant_record_id = ship['entrant__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
    selected_people_record_ids.include?(entrant_record_id)
  }
  ship_chain_ids = selected_ships.map { |ship|
    ship['ship_chain']&.gsub(/[\[\]"]/, '')&.split(',')&.first
  }.compact.uniq

  selected_chains = @ship_chains_data.select { |chain| ship_chain_ids.include?(chain['record_id']) }

  puts "Importing #{selected_chains.size} projects..." if VERBOSE

  selected_chains.each do |chain|
    # Find the user via ships data
    related_ship = selected_ships.find { |ship|
      ship_chain_id = ship['ship_chain']&.gsub(/[\[\]"]/, '')&.split(',')&.first
      ship_chain_id == chain['record_id']
    }
    unless related_ship
      puts "✗ Skipping project #{chain['record_id']}: no related ship found"
      next
    end

    # Find the person record and get slack_id
    entrant_record_id = related_ship['entrant__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
    person_record = @people_data.find { |person| person['record_id'] == entrant_record_id }
    unless person_record
      puts "✗ Skipping project #{chain['record_id']}: person record not found"
      next
    end

    entrant_slack_id = person_record['slack_id']
    user = @slack_id_to_user[entrant_slack_id]

    unless user
      puts "✗ Skipping project #{chain['record_id']}: user #{entrant_slack_id} not found"
      next
    end

    if DRY_RUN
      puts "DRY RUN: Would create project '#{chain['title']}' for user #{entrant_slack_id}" if VERBOSE
      next
    end

    # Mark user as having hackatime to bypass validation
    user.update_column(:has_hackatime, true) unless user.has_hackatime?

    project = Project.new(
      user: user,
      title: extract_string_from_json_array(chain['title']) || "Untitled Project",
      description: "Imported project", # CSV doesn't seem to have description
      category: "Something else", # Default category
      repo_link: valid_url(chain['repo_url']),
      demo_link: valid_url(chain['deploy_url']),
      created_at: chain['root_ship__created_time'] ? Time.parse(chain['root_ship__created_time']) : Time.current
    )

    if project.save
      @record_id_to_project[chain['record_id']] = project
      puts "✓ Created project: #{project.title} for #{user.display_name}" if VERBOSE
    else
      puts "✗ Failed to create project #{chain['record_id']}: #{project.errors.full_messages.join(', ')}"
    end
  end

  puts "Projects imported: #{@record_id_to_project.size}" if VERBOSE
end

def import_ship_events_and_devlogs(selected_slack_ids)
  puts "\n=== Importing Ships as Devlogs + Ship Events ===" if VERBOSE

  # Find ships for our selected users
  selected_people_records = @people_data.select { |person| selected_slack_ids.include?(person['slack_id']) }
  selected_people_record_ids = selected_people_records.map { |person| person['record_id'] }

  selected_ships = @ships_data.select { |ship|
    entrant_record_id = ship['entrant__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
    selected_people_record_ids.include?(entrant_record_id)
  }

  # Sort ships by created_time to maintain chronological order
  selected_ships.sort_by! { |ship| ship['created_time'] ? Time.parse(ship['created_time']) : Time.current }

  puts "Importing #{selected_ships.size} ships (each becomes a devlog + ship event)..." if VERBOSE

  devlogs_created = 0
  ship_events_created = 0

  selected_ships.each do |ship|
    # Find the person record and get slack_id
    entrant_record_id = ship['entrant__record_id']&.gsub(/[\[\]"]/, '')&.split(',')&.first
    person_record = @people_data.find { |person| person['record_id'] == entrant_record_id }
    unless person_record
      puts "✗ Skipping ship #{ship['record_id']}: person record not found"
      next
    end

    entrant_slack_id = person_record['slack_id']
    user = @slack_id_to_user[entrant_slack_id]

    unless user
      puts "✗ Skipping ship #{ship['record_id']}: user #{entrant_slack_id} not found"
      next
    end

    # Find the project this ship belongs to
    ship_chain_id = ship['ship_chain']&.gsub(/[\[\]"]/, '')&.split(',')&.first
    project = @record_id_to_project[ship_chain_id]
    unless project
      puts "✗ Skipping ship #{ship['record_id']}: project #{ship_chain_id} not found"
      next
    end

    ship_time = ship['created_time'] ? Time.parse(ship['created_time']) : Time.current
    work_hours = ship['hours'].to_f
    work_seconds = (work_hours * 3600).to_i

    if DRY_RUN
      puts "DRY RUN: Would create devlog (#{work_hours}h) + ship event for #{project.title} at #{ship_time}" if VERBOSE
      next
    end

    # Create devlog first (with the work duration)
    devlog_time = ship_time - 1.minute # Slightly before ship event

    # Create a simple text file attachment for the devlog
    devlog_text = "Work completed on #{project.title}: #{work_hours} hours of development."

    devlog = Devlog.new(
      user: user,
      project: project,
      text: devlog_text,
      seconds_coded: work_seconds,
      created_at: devlog_time,
      updated_at: devlog_time
    )

    # Skip devlog validations that require file attachments
    devlog.save(validate: false)

    if devlog.persisted?
      devlogs_created += 1
      puts "✓ Created devlog: #{work_hours}h for #{project.title} at #{devlog_time}" if VERBOSE
    else
      puts "✗ Failed to create devlog for ship #{ship['record_id']}: #{devlog.errors.full_messages.join(', ')}"
      next
    end

    # Create ship event after devlog
    ship_event = ShipEvent.new(
      project: project,
      created_at: ship_time,
      updated_at: ship_time
    )

    if ship_event.save
      @record_id_to_ship_event[ship['record_id']] = ship_event
      ship_events_created += 1
      puts "✓ Created ship event for #{project.title} at #{ship_time}" if VERBOSE
    else
      puts "✗ Failed to create ship event #{ship['record_id']}: #{ship_event.errors.full_messages.join(', ')}"
    end
  end

  puts "Devlogs created: #{devlogs_created}" if VERBOSE
  puts "Ship events created: #{ship_events_created}" if VERBOSE
end

def save_mappings
  puts "\n=== Saving Mappings ===" if VERBOSE

  mapping_file = 'tmp/ship_mappings.json'

  # Ensure tmp directory exists
  FileUtils.mkdir_p('tmp')

  # Convert ship_event objects to their IDs for JSON serialization
  ship_mapping_with_ids = {}
  @record_id_to_ship_event.each do |record_id, ship_event|
    ship_mapping_with_ids[record_id] = ship_event.id
  end

  mappings = {
    record_id_to_ship_event: ship_mapping_with_ids,
    record_id_to_project: @record_id_to_project.transform_values(&:id),
    created_at: Time.current.iso8601,
    stats: {
      ship_events_mapped: @record_id_to_ship_event.size,
      projects_mapped: @record_id_to_project.size
    }
  }

  File.write(mapping_file, JSON.pretty_generate(mappings))
  puts "Saved mappings to #{mapping_file}" if VERBOSE
  puts "- Ship events mapped: #{@record_id_to_ship_event.size}"
  puts "- Projects mapped: #{@record_id_to_project.size}"
end

# Main execution
selected_users = select_subset_users

if selected_users.empty?
  puts "No users selected for import. Exiting."
  exit
end

puts "\n" + "="*50
puts "IMPORT PLAN"
puts "="*50
puts "Mode: #{FULL_IMPORT ? 'FULL IMPORT' : 'SUBSET IMPORT'}"
puts "Max users: #{SUBSET_SIZE == Float::INFINITY ? 'ALL' : SUBSET_SIZE}"
puts "Users to import: #{selected_users.size}"
puts "Dry run: #{DRY_RUN ? 'YES' : 'NO'}"
puts "Verbose: #{VERBOSE ? 'YES' : 'NO'}"
puts "="*50

if DRY_RUN
  puts "\nThis is a DRY RUN. No data will be actually imported."
else
  puts "\nStarting import in 3 seconds..." if VERBOSE
  sleep 3 unless VERBOSE
end

# Import in order of dependencies
import_users(selected_users)
import_projects(selected_users)
import_ship_events_and_devlogs(selected_users)

# Save mappings for votes import script
save_mappings

puts "\n" + "="*50
puts "IMPORT COMPLETE"
puts "="*50
if VERBOSE
  puts "Final counts:"
  puts "- Users: #{User.count}"
  puts "- Projects: #{Project.count}"
  puts "- Ship Events: #{ShipEvent.count}"
  puts "- Devlogs: #{Devlog.count}"
  puts "- Votes: #{Vote.count}"
else
  puts "Created: #{@record_id_to_project.size} projects, #{@record_id_to_ship_event.size} ship events"
end
