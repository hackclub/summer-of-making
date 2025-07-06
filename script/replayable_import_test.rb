require_relative '../config/environment'

END_DATE = Date.parse("2024-11-01")
# LIMIT = 9_000

# load CSVs into memory
require 'csv'
@csv_data = Hash.new { |hash, key| hash[key] = [] }
%w[battles people ships ship_chains].each do |csv_file|
  puts "Loading #{csv_file}..."
  index = 0
  CSV.foreach("csv_data/#{csv_file}.csv", headers: true) do |row|
    # read from LIMIT if csv_file is "battles" & break out of the loop
    if defined?(LIMIT) && csv_file == "battles"
      break if index >= LIMIT
    end
    index += 1
    puts "   ...processing row: #{index}" if index % 10_000 == 0
    @csv_data[csv_file] << row.to_h
  end
  puts "   ...loaded #{@csv_data[csv_file].size} rows from #{csv_file}"
end

def find_or_create_ship(ship_id, user)
  # puts ship_id
  @ships = Hash.new { |hash, key| hash[key] = nil }
  @ships[ship_id] ||= begin
    ship_record = @csv_data["ships"].find { |project| project["record_id"] == ship_id }

    raise "Project record not found for ID: #{ship_id}" if ship_record.nil?

    # a ship doesn't directly map to our new schema. it's like a ship_event, so we need to create a project & devlog to go with it
    ship_chain_id = JSON.parse(ship_record['ship_chain']).first
    project = find_or_create_project(ship_chain_id, user)
    devlog = find_or_create_devlog(ship_record, user, project)
    ship_event = find_or_create_ship_event(ship_record, user, project)

    ship_event
  end
end

def find_or_create_project(ship_chain_id, user)
  # puts ship_chain_id
  @ship_chains ||= Hash.new { |hash, key| hash[key] = nil }
  @ship_chains[ship_chain_id] ||= begin
    ship_chain_record = @csv_data["ship_chains"].find { |project| project["record_id"] == ship_chain_id }
    raise "Project record not found for ID: #{ship_chain_id}" if ship_chain_record.nil?

    Project.find_or_initialize_by(title: ship_chain_record["record_id"]).tap do |project|
      project.user = user
      project.category = Project::CATEGORIES.first
      project.description = "IMPORTED DESCRIPTION: #{ship_chain_record["update_description"]}"
      project.created_at = ship_chain_record["created_at"]
      project.updated_at = ship_chain_record["created_at"]
      project.save!
    end
  end
end

def find_or_create_devlog(ship_record, user, project)
  @devlogs ||= Hash.new { |hash, key| hash[key] = nil }
  @devlogs[ship_record["record_id"]] ||= begin
    Devlog.find_or_initialize_by(created_at: ship_record["created_at"], project: project).tap do |devlog|
      devlog.user = user
      devlog.seconds_coded = ship_record['credited_hours'].to_f * 3_600.0
      devlog.updated_at = ship_record["created_at"]
      devlog.text = "IMPORTED DEVLOG: #{ship_record['update_description']}"
      devlog.save!
    end
  end
end

def find_or_create_ship_event(ship_record, user, project)
  @ship_events ||= Hash.new { |hash, key| hash[key] = nil }
  @ship_events[ship_record["record_id"]] ||= begin
    ShipEvent.find_or_initialize_by(created_at: ship_record["created_at"], project: project).tap do |ship_event|
      ship_event.updated_at = ship_record["created_at"]
      ship_event.save!
    end
  end
end

def find_or_create_user record_id
  @users ||= Hash.new { |hash, key| hash[key] = nil }
  @users[record_id] ||= begin
    person_record = @csv_data["people"].find { |person| person["record_id"] == record_id }
    raise "Person record not found for ID: #{record_id}" if person_record.nil?
    
    User.find_or_initialize_by(slack_id: person_record["slack_id"]).tap do |user|
      user.email = person_record["email"]
      user.has_hackatime = true
      user.display_name = person_record["identifier"]
      user.timezone = "UTC"
      user.avatar = person_record["avatar"] || "https://placehold.co/400"
      user.created_at = person_record["created_at"]
      user.updated_at = person_record["created_at"] 
      user.save!
    end
  end
end

# clear out old data
puts "Clearing old data..."
VoteChange.delete_all
HackatimeProject.delete_all
HackatimeStat.delete_all
ViewEvent.delete_all
Payout.delete_all
Vote.delete_all
Devlog.delete_all
ShipEvent.delete_all
ShipCertification.delete_all
Project.delete_all
TutorialProgress.delete_all
User.delete_all

# run through each vote & create all needed aspects
puts "Processing battles..."
@csv_data["battles"].each_with_index do |battle, index|
  if defined?(LIMIT)
    next if index >= LIMIT || Date.parse(battle["created_at"]) > END_DATE
  end

  user = find_or_create_user JSON.parse(battle["voter__record_id"]).first

  ship_event_1 = find_or_create_ship(JSON.parse(battle["winner__record_id"]).first, user)
  project_1 = ship_event_1.project

  ship_event_2 = find_or_create_ship(JSON.parse(battle["loser__record_id"]).first, user)
  project_2 = ship_event_2.project

  # find existing vote with either order (model normalizes before save)
  vote = Vote.find_by(
    user: user,
    ship_event_1: ship_event_1,
    ship_event_2: ship_event_2
  ) || Vote.find_by(
    user: user,
    ship_event_1: ship_event_2,
    ship_event_2: ship_event_1
  ) || Vote.new(
    user: user,
    ship_event_1: ship_event_1,
    ship_event_2: ship_event_2
  )
  
  unless vote.persisted?
    vote.created_at = battle["created_at"]
    vote.updated_at = battle["created_at"]
    vote.explanation = "EXPLAINATION: #{battle["explanation"]&.slice(0..1000)} other text tooo to make this long enough"
    vote.winning_project_id = project_1.id
    vote.project_1 = project_1
    vote.project_2 = project_2
    vote.save!
  end
rescue => e
  puts "Error processing battle #{index}: #{e.message}"
end

# seed an admin user for now
u = User.find_or_create_by(slack_id: "U0C7B14Q3", email: "admin@example.com", display_name: "Admin", has_hackatime: true, timezone: "UTC", avatar: "https://placehold.co/400")
u.update(is_admin: true)
