class OneTime::BackfillShopOrderPhoneNumbersJob < ApplicationJob
  queue_as :default

  def perform
    cached_idv = Hash.new { |hash, key| hash[key] = User.find(key).fetch_idv }

    # Find orders without phone numbers in their frozen_address, excluding free stickers
    orders_without_phone = ShopOrder.joins(:shop_item).where(
      "frozen_address IS NOT NULL AND (frozen_address->>'phone_number' IS NULL OR frozen_address->>'phone_number' = '')"
    ).where.not(shop_items: { type: "ShopItem::FreeStickers" }).includes(:user)

    Rails.logger.info "Found #{orders_without_phone.count} shop orders without phone numbers"

    orders_without_phone.find_each do |order|
      begin
        idv_data = cached_idv[order.user.id]

        # Extract phone number from the root identity object
        phone_number = idv_data.dig(:identity, :phone_number)

        if phone_number.present?
          # Update the frozen_address to include the phone number
          updated_address = order.frozen_address.merge("phone_number" => phone_number)
          order.update_column(:frozen_address, updated_address)

          Rails.logger.info "Updated order #{order.id} with phone number"
        else
          Rails.logger.info "No phone number found for user #{order.user.id} (order #{order.id})"
        end
      rescue => e
        Rails.logger.error "Failed to update phone number for order #{order.id}: #{e.message}"
      end
    end

    Rails.logger.info "Completed backfilling phone numbers for shop orders"
  end
end
