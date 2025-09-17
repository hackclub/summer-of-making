# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_warehouse_packages
#
#  id                 :bigint           not null, primary key
#  frozen_address     :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  theseus_package_id :string
#  user_id            :bigint           not null
#
# Indexes
#
#  index_shop_warehouse_packages_on_theseus_package_id  (theseus_package_id) UNIQUE
#  index_shop_warehouse_packages_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Shop::WarehousePackage < ApplicationRecord
  self.table_name = "shop_warehouse_packages"

  belongs_to :user
  has_many :shop_orders, foreign_key: :warehouse_package_id, dependent: :nullify

  validates :frozen_address, presence: true
  validates :theseus_package_id, uniqueness: true, allow_nil: true

  def send_to_theseus!
    Honeybadger.context(warehouse_package_id: id, shop_orders: shop_orders.pluck(:id)) do
    address_params = {
      first_name: frozen_address["first_name"],
      last_name: frozen_address["last_name"],
      line_1: frozen_address["line_1"],
      line_2: frozen_address["line_2"],
      city: frozen_address["city"],
      state: frozen_address["state"],
      postal_code: frozen_address["postal_code"],
      country: frozen_address["country"]
    }

    headline = []

    contents = shop_orders.includes(:shop_item).flat_map do |order|
      headline << order.shop_item.name
      order.get_agh_contents
    end

    # Create consistent idempotency key based on orders being fulfilled
    order_ids = shop_orders.order(:id).pluck(:id).join("-")
    idempotency_key = "som25_warehouse_package_#{Rails.env}_#{user_id}_#{order_ids}"

    retries = 0
    begin
      response = TheseusService.create_warehouse_order({
        address: address_params.compact_blank,
        contents: contents,
        tags: [ "summer-of-making", "som-warehouse-prize" ],
        recipient_email: user.email,
        user_facing_title: "Summer of Making – #{headline.join ', '}",
        idempotency_key:,
        metadata: {
          som_user: user.id,
          orders: shop_orders.map do |order|
            {
              id: order.id,
              item_name: order.shop_item.name,
              quantity: order.quantity
            }
          end
        }
      })
      ap response
      update!(theseus_package_id: response.dig("warehouse_order", "id"))
    rescue Faraday::SSLError => e
      retries += 1
      if retries <= 3
        Rails.logger.warn "SSL error sending warehouse package #{id} to Theseus (attempt #{retries}): #{e.message}. Retrying..."
        sleep(retries * 2) # Exponential backoff: 2s, 4s, 6s
        retry
      else
        Rails.logger.error "Failed to send warehouse package #{id} to Theseus after 3 retries: #{e.message}"
        raise
      end
    rescue Faraday::BadRequestError => e
      # Check if this is an idempotency error from Theseus
      body = e.response&.dig(:body)

      # Parse the JSON response body to check for idempotency error
      is_idempotency_error = false
      if body.is_a?(String)
        begin
          parsed = JSON.parse(body)
          is_idempotency_error = parsed["error"] == "idempotency_error"
        rescue JSON::ParserError
          # Not JSON, continue with generic error handling
        end
      end

      if is_idempotency_error
        # Package was created on Theseus but we never got the ID back
        Rails.logger.error "Idempotency error for warehouse package #{id}: package exists on Theseus but we don't have the ID"
        Honeybadger.notify(e, context: {
          warehouse_package_id: id,
          message: "WarehousePackage #{id} requires manual fixup - package exists on Theseus but theseus_package_id is nil",
          idempotency_key: idempotency_key,
          orders: shop_orders.pluck(:id)
        })
        # Set a placeholder ID so orders can be marked as fulfilled
        # This prevents infinite retries while flagging for manual fixup
        update!(theseus_package_id: "MANUAL_FIXUP_NEEDED_#{idempotency_key}")
        return # Don't raise, let the job complete
      end

      Rails.logger.error "Bad request sending warehouse package #{id} to Theseus: #{e.message}"
      raise
    rescue => e
        Rails.logger.error "Failed to send warehouse package #{id} to Theseus: #{e.message}"
        raise
      end
    end
  end
end
