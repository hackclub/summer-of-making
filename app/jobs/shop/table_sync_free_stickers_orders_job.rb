class Shop::TableSyncFreeStickersOrdersJob < ApplicationJob
  queue_as :free_stickers_sync

  def perform(*args)
    ShopOrder.mirror_free_stickers_orders_to_airtable! "s1GhHahY"
  end
end
