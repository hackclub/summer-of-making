class Shop::ReapFreeStickersOrdersJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    orders = ShopOrder
               .includes(:shop_item)
               .with_item_type(ShopItem::FreeStickers)
               .awaiting_periodical_fulfillment
               .where.not(frozen_address: nil)

    orders.each do |order|
      Honeybadger.context({ free_stickers_order: order.id }) do
        begin
          order.shop_item.fulfill!(order)
        rescue StandardError => e
          Honeybadger.notify(e)
          next
        end
      end
    end
  end
end
