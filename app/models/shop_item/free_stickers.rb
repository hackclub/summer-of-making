# == Schema Information
#
# Table name: shop_items
#
#  id                         :bigint           not null, primary key
#  agh_contents               :jsonb
#  description                :string
#  enabled                    :boolean
#  enabled_au                 :boolean          default(FALSE)
#  enabled_ca                 :boolean          default(FALSE)
#  enabled_eu                 :boolean          default(FALSE)
#  enabled_in                 :boolean          default(FALSE)
#  enabled_us                 :boolean          default(FALSE)
#  enabled_xx                 :boolean          default(FALSE)
#  hacker_score               :integer          default(0)
#  hcb_category_lock          :string
#  hcb_keyword_lock           :string
#  hcb_merchant_lock          :string
#  internal_description       :string
#  limited                    :boolean          default(FALSE)
#  max_qty                    :integer          default(10)
#  name                       :string
#  one_per_person_ever        :boolean          default(FALSE)
#  price_offset_au            :decimal(6, 2)    default(0.0)
#  price_offset_ca            :decimal(6, 2)    default(0.0)
#  price_offset_eu            :decimal(6, 2)    default(0.0)
#  price_offset_in            :decimal(6, 2)    default(0.0)
#  price_offset_us            :decimal(6, 2)    default(0.0)
#  price_offset_xx            :decimal(6, 2)    default(0.0)
#  requires_black_market      :boolean
#  show_in_carousel           :boolean
#  stock                      :integer
#  ticket_cost                :decimal(6, 2)
#  type                       :string
#  under_the_fold_description :text
#  usd_cost                   :decimal(6, 2)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class ShopItem::FreeStickers < ShopItem
  QUEUE_ID = "som-free-stickers"
  def fulfill!(shop_order)
    response = TheseusService.create_letter_v1(
      QUEUE_ID,
      {
        recipient_email: shop_order.user.email,
        address: shop_order.frozen_address,
        idempotency_key: "som25_free_stickers_order_#{Rails.env}_#{shop_order.id}"
      }
    )
    shop_order.mark_fulfilled!(response[:id])
  end
end
