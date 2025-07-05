#!/usr/bin/env ruby

require 'csv'

puts "Debugging data connections..."

# Load small samples
people_sample = []
CSV.foreach('csv_data/people.csv', headers: true) do |row|
  people_sample << row.to_h
  break if people_sample.size >= 5
end

ships_sample = []
CSV.foreach('csv_data/ships.csv', headers: true) do |row|
  ships_sample << row.to_h
  break if ships_sample.size >= 5
end

battles_sample = []
CSV.foreach('csv_data/battles.csv', headers: true) do |row|
  battles_sample << row.to_h
  break if battles_sample.size >= 5
end

puts "\n=== PEOPLE SAMPLE ==="
people_sample.each_with_index do |person, i|
  puts "Person #{i}: autonumber=#{person['autonumber']}, slack_id=#{person['slack_id']}, record_id=#{person['record_id']}"
end

puts "\n=== SHIPS SAMPLE ==="
ships_sample.each_with_index do |ship, i|
  puts "Ship #{i}: entrant__record_id=#{ship['entrant__record_id']}, ship_chain=#{ship['ship_chain']}"
end

puts "\n=== BATTLES SAMPLE ==="
battles_sample.each_with_index do |battle, i|
  puts "Battle #{i}: voter__record_id=#{battle['voter__record_id']}"
end

# Check for valid slack IDs
valid_slack_people = people_sample.select { |person| person['slack_id'] && person['slack_id'].match?(/^U[A-Z0-9]{10}$/) }
puts "\n=== VALID SLACK PEOPLE ==="
valid_slack_people.each do |person|
  puts "Valid: autonumber=#{person['autonumber']}, slack_id=#{person['slack_id']}"
end

# Check ships entrant IDs
ship_entrant_ids = ships_sample.map { |ship| ship['entrant__record_id'] }.compact.uniq
puts "\n=== SHIP ENTRANT IDS ==="
puts ship_entrant_ids.inspect

# Check battles voter IDs  
battle_voter_ids = battles_sample.map { |battle| battle['voter__record_id'] }.compact.uniq
puts "\n=== BATTLE VOTER IDS ==="
puts battle_voter_ids.inspect

valid_autonumbers = valid_slack_people.map { |person| person['autonumber'] }
puts "\n=== VALID AUTONUMBERS ==="
puts valid_autonumbers.inspect

puts "\n=== INTERSECTION CHECK ==="
puts "Ships & Valid: #{(ship_entrant_ids.map(&:to_s) & valid_autonumbers).inspect}"
puts "Battles & Valid: #{(battle_voter_ids.map(&:to_s) & valid_autonumbers).inspect}"
