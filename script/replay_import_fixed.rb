#!/usr/bin/env ruby

require_relative '../config/environment'
require 'csv'
require 'json'
require 'optparse'
require 'date'

class ReplayImportFixed
  def initialize(cutoff_date)
    @cutoff_date = Date.parse(cutoff_date)
    @verbose = false
    @csv_data = {}
    @id_mappings = {} # Map CSV record_id to actual database ID
    
    # Show which database we're connecting to
    puts "Environment: #{Rails.env}"
    puts "Database: #{ActiveRecord::Base.connection.current_database}"
    puts "Replaying votes up to #{@cutoff_date}"
    
    # Safety check for production
    if Rails.env.production?
      puts "ERROR: This script should not be run in production!"
      puts "Use RAILS_ENV=test or RAILS_ENV=development"
      exit 1
    end
  end

  def run
    clear_existing_data
    load_csv_data
    replay_votes_chronologically
    import_payouts
    
    puts "\nReplay completed successfully!"
    generate_payouts_for_eligible_projects
    print_summary
  end

  def verbose!(enable = true)
    @verbose = enable
  end

  private

  def clear_existing_data
    puts "Clearing existing data..."
    
    # Clear only voting and payout related tables - keep users/projects/devlogs/ship_events
    tables_to_clear = [
      'vote_changes',
      'votes', 
      'payouts'
    ]
    
    ActiveRecord::Base.connection.transaction do
      tables_to_clear.each do |table|
        if ActiveRecord::Base.connection.table_exists?(table)
          ActiveRecord::Base.connection.execute("TRUNCATE #{table} CASCADE")
          puts "Cleared #{table}" if @verbose
        end
      end
    end
    
    puts "Existing data cleared."
  end

  def load_csv_data
    puts "Loading CSV data into memory..."
    
    # Load all CSV data into memory for lookup with correct file names
    @csv_data[:users] = load_csv_as_hash('csv_data/people.csv', 'record_id')
    @csv_data[:ships] = load_csv_as_hash('csv_data/ships.csv', 'record_id')
    @csv_data[:payouts] = load_csv_as_hash('csv_data/doubloon_adjustments.csv', 'record_id') rescue {}
    
    puts "CSV data loaded: #{@csv_data[:users].size} users, #{@csv_data[:ships].size} ships"
  end

  def load_csv_as_hash(filename, key_field)
    return {} unless File.exist?(filename)
    
    data = {}
    CSV.foreach(filename, headers: true) do |row|
      data[row[key_field]] = row
    end
    data
  end

  def replay_votes_chronologically
    puts "Replaying votes chronologically..."
    
    csv_file = 'csv_data/battles.csv'
    unless File.exist?(csv_file)
      puts "Warning: #{csv_file} not found. Cannot replay votes."
      return
    end

    # Load and sort all votes by creation date
    votes_data = []
    CSV.foreach(csv_file, headers: true) do |row|
      created_at = parse_date(row['created_at'])
      next unless created_at && created_at <= @cutoff_date
      
      votes_data << {
        row: row,
        created_at: created_at
      }
    end
    
    votes_data.sort_by! { |vote| vote[:created_at] }
    
    imported_count = 0
    skipped_count = 0
    
    votes_data.each_with_index do |vote_data, index|
      row = vote_data[:row]
      created_at = vote_data[:created_at]
      
      puts "Processing vote #{index + 1}/#{votes_data.size}..." if @verbose && (index % 100 == 0)
      
      begin
        # Get voter and ships from the battle data
        # Parse JSON arrays for voter, winner, loser fields
        voter_id = parse_json_array_field(row['voter'])
        winner_id = parse_json_array_field(row['winner'])
        loser_id = parse_json_array_field(row['loser'])
        
        # battles.csv represents votes between two ships (winner vs loser)
        
        unless voter_id && winner_id && loser_id
          puts "Skipping vote - missing voter (#{voter_id}), winner (#{winner_id}), or loser (#{loser_id})" if @verbose
          skipped_count += 1
          next
        end
        
        # Ensure voter exists and get the actual database ID
        actual_voter_id = ensure_user_exists(voter_id)
        unless actual_voter_id
          puts "Skipping vote - could not create voter #{voter_id}" if @verbose
          skipped_count += 1
          next
        end
        
        # Ensure both ship events exist
        winner_ship_event_id = ensure_ship_event_exists(winner_id)
        loser_ship_event_id = ensure_ship_event_exists(loser_id)
        
        unless winner_ship_event_id && loser_ship_event_id
          puts "Skipping vote - could not create ship events (winner: #{winner_id}, loser: #{loser_id})" if @verbose
          skipped_count += 1
          next
        end
        
        # Check for duplicate votes using actual database IDs (either direction)
        if Vote.exists?(user_id: actual_voter_id, ship_event_1_id: winner_ship_event_id, ship_event_2_id: loser_ship_event_id) ||
           Vote.exists?(user_id: actual_voter_id, ship_event_1_id: loser_ship_event_id, ship_event_2_id: winner_ship_event_id)
          puts "Skipping duplicate vote: user #{actual_voter_id} -> ships #{winner_ship_event_id} vs #{loser_ship_event_id}" if @verbose
          skipped_count += 1
          next
        end
        
        # Create the vote (battle between two ship events)
        explanation = row['explanation']&.strip
        explanation = "Imported vote from CSV data" if explanation.blank? || explanation.length < 10
        
        # Get the winning project ID for ELO calculation
        winner_ship_event = ShipEvent.find(winner_ship_event_id)
        winning_project_id = winner_ship_event.project_id
        
        vote = Vote.new(
          user_id: actual_voter_id,
          ship_event_1_id: winner_ship_event_id,
          ship_event_2_id: loser_ship_event_id,
          explanation: explanation,
          created_at: created_at,
          updated_at: created_at
        )
        vote.winning_project_id = winning_project_id
        
        if vote.save
          imported_count += 1
          puts "Replayed vote: user #{vote.user_id} -> ships #{vote.ship_event_1_id} vs #{vote.ship_event_2_id} at #{created_at}" if @verbose
        else
          puts "Failed to save vote: #{vote.errors.full_messages.join(', ')}"
          skipped_count += 1
        end
      rescue => e
        puts "Error replaying vote: #{e.message}"
        puts e.backtrace.first(3).join("\n") if @verbose
        skipped_count += 1
      end
    end
    
    puts "Votes: #{imported_count} replayed, #{skipped_count} skipped"
  end

  def ensure_user_exists(user_id)
    # Check if we already mapped this user
    return @id_mappings[:users][user_id] if @id_mappings[:users] && @id_mappings[:users][user_id]
    
    user_data = @csv_data[:users][user_id]
    return false unless user_data
    
    begin
      # Find existing user by slack_id first
      slack_id = user_data['slack_id']
      existing_user = User.find_by(slack_id: slack_id) if slack_id.present?
      
      if existing_user
        # Store the mapping and return existing user
        @id_mappings[:users] ||= {}
        @id_mappings[:users][user_id] = existing_user.id
        puts "Found existing user: #{existing_user.display_name} (ID: #{existing_user.id})" if @verbose
        return existing_user.id
      else
        puts "Could not find existing user for CSV user #{user_id} with slack_id #{slack_id}" if @verbose
        return false
      end
    rescue => e
      puts "Error finding user #{user_id}: #{e.message}"
      return false
    end
  end

  def ensure_ship_event_exists(ship_id)
    # Check if we already mapped this ship event
    return @id_mappings[:ships][ship_id] if @id_mappings[:ships] && @id_mappings[:ships][ship_id]
    
    ship_data = @csv_data[:ships][ship_id]
    return nil unless ship_data
    
    # Try to find existing ship event by matching project and timestamp
    ship_title = ship_data['title']
    ship_time = parse_date(ship_data['created_time'])
    
    # Find ship event by approximate title and time match
    existing_ship = ShipEvent.joins(:project)
                            .where("projects.title ILIKE ?", "%#{ship_title&.slice(0, 50)}%")
                            .where("ship_events.created_at BETWEEN ? AND ?", ship_time - 1.day, ship_time + 1.day)
                            .first
    
    if existing_ship
      @id_mappings[:ships] ||= {}
      @id_mappings[:ships][ship_id] = existing_ship.id
      puts "Found existing ship: #{existing_ship.id} for '#{ship_title}'" if @verbose
      return existing_ship.id
    else
      puts "Could not find existing ship for '#{ship_title}' at #{ship_time}" if @verbose
      return nil
    end
    
    begin
      # Get the entrant (ship owner) from the ship data
      entrant_id = parse_json_array_field(ship_data['entrant'])
      
      # Ensure the ship owner exists and get actual database ID
      actual_entrant_id = ensure_user_exists(entrant_id)
      unless actual_entrant_id
      puts "Cannot create ship event #{ship_id} - entrant #{entrant_id} failed" if @verbose
        return nil
      end
      
      # For now, create a simple project (since projects aren't separate in this CSV structure)
      actual_project_id = ensure_project_exists_for_ship(ship_data, actual_entrant_id)
      unless actual_project_id
      puts "Cannot create ship event #{ship_id} - project creation failed" if @verbose
        return nil
        end
      
      # Create a devlog for the work done before shipping
      hours = ship_data['hours']&.to_f || 0
      hackatime_seconds = (hours * 3600).to_i
      
      devlog_created_at = parse_date(ship_data['created_time']) - 1.hour # Create devlog before ship
      
      devlog = Devlog.new(
        project_id: actual_project_id,
        user_id: actual_entrant_id,
        text: "Work done for ship: #{ship_data['title']}",
        last_hackatime_time: hackatime_seconds,
        created_at: devlog_created_at,
        updated_at: devlog_created_at
      )
      
      unless devlog.save
        puts "Warning: Failed to create devlog for ship #{ship_id}: #{devlog.errors.full_messages.join(', ')}" if @verbose
      end
      
      # Create the ship event
      ship_event = ShipEvent.new(
        project_id: actual_project_id,
        created_at: parse_date(ship_data['created_time']),
        updated_at: parse_date(ship_data['created_time'])
      )
      
      if ship_event.save
        # Store the mapping from CSV record_id to actual database ID
        @id_mappings[:ships] ||= {}
        @id_mappings[:ships][ship_id] = ship_event.id
        puts "Created ship event: #{ship_event.id} with #{hours}h devlog - #{ship_data['title']}" if @verbose
        return ship_event.id
      else
        puts "Failed to create ship event #{ship_id}: #{ship_event.errors.full_messages.join(', ')}"
        return nil
      end
    rescue => e
      puts "Error creating ship event #{ship_id}: #{e.message}"
      return nil
    end
  end

  def ensure_project_exists_for_ship(ship_data, actual_entrant_id)
    ship_title = ship_data['title']
    
    # Create a project ID based on the ship to avoid duplicates
    project_key = "project_for_#{ship_data['record_id']}"
    
    # Check if we already created this project
    return @id_mappings[:projects][project_key] if @id_mappings[:projects] && @id_mappings[:projects][project_key]
    
    begin
      project = Project.new(
        title: ship_title || "Project for Ship #{ship_data['record_id']}",
        description: "Auto-generated project for ship: #{ship_title}",
        user_id: actual_entrant_id,
        category: "Something else", # Default category
        hackatime_project_keys: [], # Empty array for Hackatime
        created_at: parse_date(ship_data['created_time']),
        updated_at: parse_date(ship_data['created_time'])
      )
      
      if project.save
        # Store the mapping from project key to actual database ID
        @id_mappings[:projects] ||= {}
        @id_mappings[:projects][project_key] = project.id
        puts "Created project: #{project.title} (ID: #{project.id})" if @verbose
        return project.id
      else
        puts "Failed to create project #{project_key}: #{project.errors.full_messages.join(', ')}"
        return nil
      end
    rescue => e
      puts "Error creating project #{project_key}: #{e.message}"
      return nil
    end
  end

  def import_payouts
    puts "Importing payouts for existing ship events..."
    
    return unless @csv_data[:payouts]
    
    imported_count = 0
    skipped_count = 0
    
    # Sort payouts by creation date
    payouts_data = []
    @csv_data[:payouts].each do |payout_id, payout_data|
      created_at = parse_date(payout_data['created_at']) rescue nil
      next unless created_at && created_at <= @cutoff_date
      
      payouts_data << {
        row: payout_data,
        created_at: created_at
      }
    end
    
    payouts_data.sort_by! { |payout| payout[:created_at] }
    
    payouts_data.each do |payout_data|
      row = payout_data[:row]
      created_at = payout_data[:created_at]
      
      begin
        # Check if the ship event exists (only import payouts for ships we've created)
        ship_id = row['ship_id'] # This might not exist in doubloon_adjustments
        next unless ship_id && ShipEvent.exists?(ship_id)
        
        payout = Payout.new(
          id: row['record_id'],
          ship_event_id: ship_id,
          amount: row['amount']&.to_f || 0,
          project_title: "Payout for ship #{ship_id}",
          created_at: created_at,
          updated_at: created_at
        )
        
        if payout.save
          imported_count += 1
          puts "Imported payout: $#{payout.amount} for ship #{payout.ship_event_id}" if @verbose
        else
          puts "Failed to save payout #{row['record_id']}: #{payout.errors.full_messages.join(', ')}"
          skipped_count += 1
        end
      rescue => e
        puts "Error importing payout #{row['record_id']}: #{e.message}"
        skipped_count += 1
      end
    end
    
    puts "Payouts: #{imported_count} imported, #{skipped_count} skipped"
  end

  def generate_payouts_for_eligible_projects
    puts "Generating payouts for projects with 18+ votes..."
    
    # First, enable payout generation by creating a genesis payout if none exists
    unless Payout.where(payable_type: "ShipEvent").any?
      puts "Creating genesis payout to enable automatic payout generation..."
      
      # Find a project with ship events to create genesis payout
      project_with_ship = Project.joins(:ship_events).first
      if project_with_ship && project_with_ship.ship_events.any?
        genesis_payout = Payout.create!(
          amount: 0.01, # Minimal amount
          payable: project_with_ship.ship_events.first,
          user: project_with_ship.user,
          reason: "Genesis payout to enable automatic payout system"
        )
        puts "Created genesis payout: #{genesis_payout.id}"
      else
        puts "No ship events found for genesis payout creation"
        return
      end
    end
    
    # Find projects with 18+ votes that need payouts
    project_ids_with_enough_votes = Project.joins(:vote_changes)
                                          .group('projects.id')
                                          .having('COUNT(vote_changes.id) >= ?', 18)
                                          .pluck('projects.id')
    
    puts "Found #{project_ids_with_enough_votes.count} projects with 18+ votes"
    
    generated_count = 0
    project_ids_with_enough_votes.each_with_index do |project_id, index|
      puts "Processing project #{index + 1}/#{project_ids_with_enough_votes.count}..." if @verbose && (index % 50 == 0)
      
      begin
        project = Project.find(project_id)
        existing_payouts = Payout.where(payable_type: "ShipEvent", payable_id: project.ship_events.pluck(:id)).count
        
        project.issue_payouts
        
        new_payouts = Payout.where(payable_type: "ShipEvent", payable_id: project.ship_events.pluck(:id)).count
        if new_payouts > existing_payouts
          generated_count += new_payouts - existing_payouts
          puts "Generated #{new_payouts - existing_payouts} payouts for '#{project.title}'" if @verbose
        end
      rescue => e
        puts "Error generating payouts for project #{project_id}: #{e.message}"
      end
    end
    
    puts "Generated #{generated_count} payouts for eligible projects"
  end

  def parse_date(date_string)
    return nil if date_string.nil? || date_string.empty?
    
    # Handle different date formats
    begin
      DateTime.parse(date_string)
    rescue ArgumentError => e
      puts "Warning: Could not parse date '#{date_string}': #{e.message}" if @verbose
      nil
    end
  end

  def parse_json_array_field(field_value)
    return nil if field_value.nil? || field_value.empty?
    
    # If it looks like a JSON array, parse it and get the first item
    if field_value.start_with?('[') && field_value.end_with?(']')
      begin
        parsed = JSON.parse(field_value)
        return parsed.first if parsed.is_a?(Array) && !parsed.empty?
      rescue JSON::ParserError => e
        puts "Warning: Could not parse JSON array '#{field_value}': #{e.message}" if @verbose
        return nil
      end
    end
    
    # Return as-is if not a JSON array
    field_value
  end

  def print_summary
    puts "\n=== Import Summary ==="
    puts "Cutoff date: #{@cutoff_date}"
    puts "Users: #{User.count}"
    puts "Projects: #{Project.count}"
    puts "Ship events: #{ShipEvent.count}"
    puts "Votes: #{Vote.count}"
    puts "Payouts: #{Payout.count}"
    puts "======================"
  end
end

# Command line interface
if __FILE__ == $0
  cutoff_date = nil
  verbose = false
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] DATE"
    opts.on("-v", "--verbose", "Enable verbose output") { verbose = true }
    opts.on("-h", "--help", "Show this help") { puts opts; exit }
  end.parse!
  
  if ARGV.empty?
    puts "Error: Please provide a cutoff date (e.g., 2024-07-09)"
    puts "Usage: #{$0} [options] DATE"
    exit 1
  end
  
  cutoff_date = ARGV[0]
  
  begin
    importer = ReplayImportFixed.new(cutoff_date)
    importer.verbose!(verbose)
    importer.run
  rescue ArgumentError => e
    puts "Error: Invalid date format. Please use YYYY-MM-DD format."
    puts "Example: #{$0} 2024-07-09"
    exit 1
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace if verbose
    exit 1
  end
end
