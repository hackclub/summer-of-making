# frozen_string_literal: true

class Shop::ProcessSinkeningStickersJob < ApplicationJob
  queue_as :default

  def perform
    # Get all pending sinkening balloon orders
    sinkening_orders = ShopOrder.joins(:shop_item)
                                .where(shop_items: { type: "ShopItem::SinkeningBalloons" })
                                .where(aasm_state: "awaiting_periodical_fulfillment")

    return if sinkening_orders.empty?

    # Process each order individually (one letter per order)
    sinkening_orders.each do |order|
      Honeybadger.context(sinkening_order: order.id) do
        process_individual_order(order)
      end
    end
  end

  private

  def process_individual_order(order)
    user = order.user

    rubber_stamps = "sinkening balloons!"

    begin
      response = TheseusService.create_letter_v1(
        "som-sinkening",
        {
          recipient_email: user.email,
          address: order.frozen_address,
          rubber_stamps: rubber_stamps,
          idempotency_key: "som25_sinkening_#{Rails.env}_#{order.id}",
          metadata: {
            som_user: user.id,
            order: {
              id: order.id,
              item_name: order.shop_item.name,
              quantity: order.quantity
            }
          }
        }
      )
    rescue Faraday::BadRequestError => e
      return
    end

    order.mark_fulfilled!(response[:id], nil, "System - Sinkening Sticker")
  end
end
