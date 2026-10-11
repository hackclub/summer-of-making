class Shop::ReapFreeStickersOrdersJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    orders = ShopOrder
               .includes(:shop_item)
               .with_item_type(ShopItem::FreeStickers)
               .awaiting_periodical_fulfillment
               .where.not(frozen_address: nil)

    orders.each do |order|
      begin
        order.shop_item.fulfill!(order)
      rescue StandardError => e
        Rails.logger.error("Failed to fulfill free stickers order #{order.id}: #{e.full_message}")
        next
      end
    end
  end
end
