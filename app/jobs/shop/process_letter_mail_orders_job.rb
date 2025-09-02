# frozen_string_literal: true

class Shop::ProcessLetterMailOrdersJob < ApplicationJob
  queue_as :default

  def perform
    # Get all pending_nightly letter mail orders
    letter_mail_orders = ShopOrder.joins(:shop_item)
                                  .where(shop_items: { type: "ShopItem::LetterMail" })
                                  .where(aasm_state: "awaiting_periodical_fulfillment")

    return if letter_mail_orders.empty?

    # Group orders by user and frozen_address for coalescing
    grouped_orders = letter_mail_orders.group_by do |order|
      [ order.user_id, order.frozen_address ]
    end

    grouped_orders.each do |(user_id, frozen_address), orders|
      Honeybadger.context(letter_mail_orders: orders.pluck(:id)) do
        process_coalesced_orders(orders, frozen_address)
      end
    end
  end

  private

  def process_coalesced_orders(orders, frozen_address)
    user = orders.first.user

    # Build rubber stamp content with quantities
    rubber_stamps = build_rubber_stamps(orders)

    # Create letter via Theseus
    begin
      response = TheseusService.create_letter_v1(
        "som-fulfillment",
        {
          recipient_email: user.email,
          address: frozen_address,
          rubber_stamps: rubber_stamps,
          idempotency_key: "som25_letter_mail_#{Rails.env}_#{generate_coalesced_key(orders)}",
          metadata: {
            som_user: user.id,
            orders: orders.map do |order|
              {
                id: order.id,
                item_name: order.item.name,
                quantity: order.quantity
              }
            end
          }
        }
      )
    rescue Faraday::BadRequestError => e
      return
    end

    # Mark all orders as fulfilled
    orders.each do |order|
      order.mark_fulfilled!(response[:id], nil, "System - Letter Mail Batch")
    end
  end

  def build_rubber_stamps(orders)
    # Group by item name and sum quantities
    item_quantities = orders.group_by { |order| order.shop_item.name }
                            .transform_values { |group| group.sum(&:quantity) }

    # Format as "1x Item Name\n2x Another Item"
    item_quantities.map { |name, qty| "#{qty}x #{name}" }.join("\n")
  end

  def generate_coalesced_key(orders)
    # Create a stable key based on order IDs for idempotency
    order_ids = orders.map(&:id).sort
    Digest::SHA256.hexdigest(order_ids.join("_"))[0, 16]
  end
end
