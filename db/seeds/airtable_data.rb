# frozen_string_literal: true

require 'net/http'
require 'json'
require 'open-uri'

# Airtable data import
puts "Loading Airtable data..."

airtable_key = ENV['HIGHSEAS_AIRTABLE_KEY']
if airtable_key.blank?
  puts "⚠️  HIGHSEAS_AIRTABLE_KEY not set, skipping Airtable import"
  return
end

begin
  # Airtable API configuration
  app_id = 'appNF8MGrk5KKcYZx'
  table_id = 'tblAbzAZb4pdWI1tC'

  uri = URI("https://api.airtable.com/v0/#{app_id}/#{table_id}?filterByFormula={enabled}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{airtable_key}"

  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    records = data['records']

    puts "Found #{records.count} records in Airtable"

    records.each do |record|
      fields = record['fields']

      name_field = fields['Name'] || fields['name'] || fields['Title'] || fields['title'] || fields['Item Name']

      unless name_field.present?
        puts "  ⚠️  Skipping record - no name field found"
        next
      end

      item_type = if fields["identifier"] == "item_free_stickers_41"
                    'ShopItem::FreeStickers'
      elsif fields['hcb_grant_merchants'].present? || fields['hcb_grant_amount_cents'].present?
                    'ShopItem::HCBGrant'
      elsif fields['fulfillment_type'] = "hq_mail"
                    'ShopItem::HQMailItem'
      elsif [ 'third_party_physical', 'special_fulfillment' ].include?(fields['fulfillment_type'])
                    'ShopItem::SpecialFulfillmentItem'
      elsif fields['agh_skus'].present?
                    'ShopItem::WarehouseItem'
      else
                    puts "  ❌ ERROR: Cannot determine type for #{name_field} - no identifying fields found"
                    next
      end

      existing_item = ShopItem.find_by(name: name_field)
      if existing_item
        # next
        puts "  🗑️  Deleting existing: #{existing_item.name}"
        existing_item.destroy
      end

      shop_item = ShopItem.create(name: name_field) do |item|
        item.type = item_type
        item.description = fields['subtitle'] # airtable subtitle -> db description
        item.internal_description = fields['description'] # airtable description -> internal_description
        item.ticket_cost = fields['tickets_us']&.to_f || 0
        item.usd_cost = fields['unit_cost']&.to_f || fields['fair_market_value']&.to_f || 0
        item.hacker_score = fields['hacker_score']&.to_i || 0
        item.requires_black_market = false
        item.one_per_person_ever = %w[ShopItem::SpecialFulfillmentItem ShopItem::FreeStickers].include?(item_type) ? true : false
        item.show_in_carousel = fields['show_in_carousel']

        if fields['image_url'].present?
          begin
            image_uri = URI.parse(fields['image_url'])
            downloaded_image = image_uri.open
            item.image.attach(io: downloaded_image, filename: File.basename(image_uri.path))
          rescue => e
            puts "    ⚠️  Could not download image for #{name_field}: #{e.message}"
          end
        end

        # Set type-specific fields
        if item_type == 'ShopItem::WarehouseItem' && fields['agh_skus'].present?
          begin
            skus = JSON.parse(fields['agh_skus'] || '[]')
            item.agh_contents = {
              skus: skus,
              image_url: fields['image_url'],
              identifier: fields['identifier'],
              needs_address: fields['needs_addy'] || false,
              customs_likely: fields['customs_likely'] || false
            }
          rescue JSON::ParserError
            item.agh_contents = nil
          end
        elsif item_type == 'ShopItem::HCBGrant'
          item.hcb_merchant_lock = fields['hcb_grant_merchants']
        end
      end

      if shop_item.persisted?
        puts "  ✓ Created: #{shop_item.name}"
      else
        puts "  ❌ Failed to save: #{shop_item.name} - #{shop_item.errors.full_messages.join(', ')}"
      end
    end

    puts "Airtable import completed!"

    begin
      sync_count = Airtable::HighSeasBook::StorySubmission.sync_with_airtable
      puts "found #{sync_count} records"

      processed_submissions = 0
      attached_photos_count = 0
      Airtable::HighSeasBook::StorySubmission.all.each do |submission|
        next unless submission.airtable_fields["Show in Summer of Making"] == true
        processed_submissions += 1
        photos_field = submission.airtable_fields["Photos (Optional)"]
        next if photos_field.blank?
        if submission.photos.attached?
          submission.photos.each(&:purge)
          puts "destroy dupes #{submission.id}."
        end
        photos_field.each do |photo_data|
          url = photo_data["url"]
          if url.present?
            begin
              submission.attach_photo_from_url(url)
              attached_photos_count += 1
            rescue => e
            puts "getting #{url} for submission ID #{submission.id}: #{e.message}"
            end
          end
        end
      end
      puts "  Processed #{processed_submissions} StorySubmissions for photo attachment."
      puts "  Attempted to attach #{attached_photos_count} photos in total."
    rescue StandardError => e
    puts "error #{e.message}"
    puts "#{e.backtrace.first(5).join("\\n  ")}"
    end

  else
    puts "❌ Failed to fetch Airtable data: #{response.code} #{response.message}"
  end

rescue => e
  puts "❌ Error importing Airtable data: #{e.message}"
end
