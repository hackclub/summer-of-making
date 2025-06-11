# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Load essential data for all environments
load Rails.root.join('db/seeds/production.rb')

# Load development data only in dev/test
if Rails.env.development? || Rails.env.test?
  load Rails.root.join('db/seeds/development.rb')
end

# Load airtable data (works in all envs with find_or_create)
if ENV['HIGHSEAS_AIRTABLE_KEY'].present?
  # load Rails.root.join('db/seeds/airtable_data.rb')
else
  puts "⚠️ HIGHSEAS_AIRTABLE_KEY not set, skipping Airtable import"
end

puts "✅ Database seeding completed!"
