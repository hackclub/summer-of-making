# frozen_string_literal: true

class Shop::ProcessWarehouseOrdersJob < ApplicationJob
  queue_as :default

  def perform
    # Get all pending warehouse item orders
    warehouse_orders = ShopOrder.joins(:shop_item)
                                .where(shop_items: { type: %w[ShopItem::WarehouseItem ShopItem::PileOfStickersItem] })
                                .where(aasm_state: "awaiting_periodical_fulfillment")

    return if warehouse_orders.empty?

    # Group orders by user and frozen_address for coalescing
    grouped_orders = warehouse_orders.group_by do |order|
      [ order.user_id, order.frozen_address ]
    end

    grouped_orders.each do |(user_id, frozen_address), orders|
      process_coalesced_orders(orders, user_id, frozen_address)
    end
  end

  private

  def process_coalesced_orders(orders, user_id, frozen_address)
    # Create warehouse package
    warehouse_package = Shop::WarehousePackage.create!(
      user_id: user_id,
      frozen_address: frozen_address
    )

    # Assign all orders to this package
    orders.each do |order|
      order.update!(warehouse_package: warehouse_package)
    end

    # Send to Theseus now that orders are assigned
    warehouse_package.send_to_theseus!

    # Mark orders as fulfilled
    orders.each do |order|
      order.mark_fulfilled!(warehouse_package.theseus_package_id, nil, "System - Warehouse Package")
    end
  end
end
