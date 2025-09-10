# == Schema Information
#
# Table name: shop_items
#
#  id                                :bigint           not null, primary key
#  agh_contents                      :jsonb
#  description                       :string
#  enabled                           :boolean
#  enabled_au                        :boolean          default(FALSE)
#  enabled_ca                        :boolean          default(FALSE)
#  enabled_eu                        :boolean          default(FALSE)
#  enabled_in                        :boolean          default(FALSE)
#  enabled_us                        :boolean          default(FALSE)
#  enabled_xx                        :boolean          default(FALSE)
#  hacker_score                      :integer          default(0)
#  hcb_category_lock                 :string
#  hcb_keyword_lock                  :string
#  hcb_merchant_lock                 :string
#  hcb_preauthorization_instructions :text
#  internal_description              :string
#  limited                           :boolean          default(FALSE)
#  max_qty                           :integer          default(10)
#  name                              :string
#  one_per_person_ever               :boolean          default(FALSE)
#  price_offset_au                   :decimal(6, 2)    default(0.0)
#  price_offset_ca                   :decimal(6, 2)    default(0.0)
#  price_offset_eu                   :decimal(6, 2)    default(0.0)
#  price_offset_in                   :decimal(6, 2)    default(0.0)
#  price_offset_us                   :decimal(6, 2)    default(0.0)
#  price_offset_xx                   :decimal(6, 2)    default(0.0)
#  requires_black_market             :boolean
#  show_in_carousel                  :boolean
#  site_action                       :integer
#  stock                             :integer
#  ticket_cost                       :decimal(6, 2)
#  type                              :string
#  under_the_fold_description        :text
#  usd_cost                          :decimal(6, 2)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  idx_shop_items_enabled_black_market_price  (enabled,requires_black_market,ticket_cost)
#  idx_shop_items_regional_enabled            (enabled,enabled_us,enabled_eu,enabled_in,enabled_ca,enabled_au,enabled_xx)
#  idx_shop_items_type_enabled                (type,enabled)
#
class ShopItem::PileOfStickersItem < ShopItem::WarehouseItem
  def get_agh_contents(order)
    return [] unless agh_contents.present?

    base_qty = agh_contents["base_qty"]
    possible_stickers = agh_contents["choices"]

    desired_qty = base_qty * order.quantity

    # not an efficient way to do it, but it reads like poetry
    possible_stickers.shuffle.cycle.take(desired_qty).tally.map do |sku, quantity|
      {
        sku:,
        quantity:
      }
    end
  end
end
