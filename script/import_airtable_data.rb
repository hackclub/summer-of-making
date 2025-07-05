#!/usr/bin/env ruby

require_relative '../config/environment'
require 'csv'
require 'set'

puts "Starting Airtable data import..."

# ID mapping storage
user_id_map = {}
project_id_map = {}

# Step 1: Clear existing data
puts "Clearing existing data..."
ActiveRecord::Base.transaction do
  Vote.delete_all
  Devlog.delete_all
  Project.delete_all
  User.delete_all
  puts "Cleared all data"
end

# Step 2: Generate test users based on ships data
puts "Generating users from ships data..."
user_count = 0
slack_ids = Set.new

# First pass: collect all unique slack_ids from ships
CSV.foreach('csv_data/ships.csv', headers: true) do |row|
  slack_id = row['entrant__slack_id']
  slack_ids.add(slack_id) if slack_id.present?
end

# Create users for each slack_id
slack_ids.each_with_index do |slack_id, index|
  user = User.create!(
    slack_id: slack_id,
    display_name: "User #{index + 1}",
    email: "user#{index + 1}@example.com",
    timezone: 'UTC',
    avatar: 'https://via.placeholder.com/192',
    is_admin: false,
    has_hackatime: false
  )
  
  user_count += 1
  
  if user_count % 100 == 0
    puts "  Generated #{user_count} users..."
  end
end

puts "Generated #{user_count} users"

# Step 3: Import Projects from ships.csv
puts "Importing projects from ships.csv..."
project_count = 0

CSV.foreach('csv_data/ships.csv', headers: true) do |row|
  # Find user by slack_id
  slack_id = row['entrant__slack_id']
  next unless slack_id
  
  user = User.find_by(slack_id: slack_id)
  next unless user
  
  project = Project.create!(
    user: user,
    title: row['title'] || 'Untitled Project',
    description: row['description'],
    demo_link: row['demo_url'],
    repo_link: row['repo_url'],
    readme_link: row['readme_url'],
    is_shipped: row['shipped'] == 'true',
    category: row['category'] || 'other',
    rating: (row['rating'] || 1000).to_i
  )
  
  project_id_map[row['record_id']] = project.id
  project_count += 1
  
  if project_count % 1000 == 0
    puts "  Imported #{project_count} projects..."
  end
end

puts "Imported #{project_count} projects"

# Step 4: Import Battles as Votes
puts "Importing votes from battles.csv..."
vote_count = 0

CSV.foreach('csv_data/battles.csv', headers: true) do |row|
  # Find user and projects
  voter_slack_id = row['voter_slack_id'] || row['user_slack_id']
  next unless voter_slack_id
  
  user = User.find_by(slack_id: voter_slack_id)
  next unless user
  
  project_1_id = project_id_map[row['project_1_record_id']] || project_id_map[row['ship_1']]
  project_2_id = project_id_map[row['project_2_record_id']] || project_id_map[row['ship_2']]
  
  next unless project_1_id && project_2_id
  
  project_1 = Project.find_by(id: project_1_id)
  project_2 = Project.find_by(id: project_2_id)
  
  next unless project_1 && project_2
  
  # Determine winner
  winner_record_id = row['winner'] || row['winning_ship']
  winning_project_id = project_id_map[winner_record_id]
  
  vote = Vote.create!(
    user: user,
    project_1: project_1,
    project_2: project_2,
    winning_project_id: winning_project_id,
    explanation: row['explanation'] || '',
    status: 'completed',
    time_spent_voting_ms: (row['time_spent_ms'] || 30000).to_i
  )
  
  vote_count += 1
  
  if vote_count % 5000 == 0
    puts "  Imported #{vote_count} votes..."
  end
end

puts "Imported #{vote_count} votes"

# Step 5: Create some basic devlogs from ship_chains.csv
puts "Importing devlogs from ship_chains.csv..."
devlog_count = 0

CSV.foreach('csv_data/ship_chains.csv', headers: true) do |row|
  # Find project and user
  ship_record_id = row['ship'] || row['ship_record_id']
  next unless ship_record_id
  
  project_id = project_id_map[ship_record_id]
  next unless project_id
  
  project = Project.find_by(id: project_id)
  next unless project
  
  # Create devlog entry
  devlog = Devlog.create!(
    user: project.user,
    project: project,
    text: row['description'] || row['text'] || 'Project update',
    seconds_coded: (row['hours'] || 1).to_f * 3600,
    likes_count: 0,
    comments_count: 0
  )
  
  devlog_count += 1
  
  if devlog_count % 1000 == 0
    puts "  Imported #{devlog_count} devlogs..."
  end
end

puts "Imported #{devlog_count} devlogs"

# Final counts
puts "\nImport complete!"
puts "Final counts:"
puts "- Users: #{User.count}"
puts "- Projects: #{Project.count}"
puts "- Votes: #{Vote.count}"
puts "- Devlogs: #{Devlog.count}"
