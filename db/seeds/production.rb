# frozen_string_literal: true

# Production seed data (essential records that should exist in all environments)

puts "Loading essential production data..."

# Add any essential data that should exist in production
# For example:
# - Default admin users
# - Required configuration records
# - Essential shop items that should always exist

ShopItem::FreeStickers.find_or_create_by!(name: "Free Stickers!") do |item|
  item.one_per_person_ever = true
  item.description = "we'll actually send you these!"
  item.ticket_cost = 0
end

puts "Production data loaded!"
