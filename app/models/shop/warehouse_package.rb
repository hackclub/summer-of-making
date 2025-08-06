# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_warehouse_packages
#
#  id                  :bigint           not null, primary key
#  frozen_address      :jsonb            not null
#  theseus_package_id  :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_shop_warehouse_packages_on_theseus_package_id  (theseus_package_id) UNIQUE
#  index_shop_warehouse_packages_on_user_id            (user_id)
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

    response = TheseusService.create_warehouse_order({
      address: address_params.compact_blank,
      contents: contents,
      tags: [ "summer-of-making", "som-warehouse-prize" ],
      recipient_email: user.email,
      user_facing_title: "Summer of Making – #{headline.join ', '}"
    })
    ap response
    update!(theseus_package_id: response.dig("warehouse_order", "id"))
  rescue => e
    Rails.logger.error "Failed to send warehouse package #{id} to Theseus: #{e.message}"
    raise
  end
end
