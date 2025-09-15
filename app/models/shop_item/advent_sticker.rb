# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_items
#
#  id                                :bigint           not null, primary key
#  advent_announced                  :boolean          default(FALSE), not null
#  agh_contents                      :jsonb
#  campfire_only                     :boolean          default(TRUE), not null
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
#  sale_percentage                   :integer
#  show_in_carousel                  :boolean
#  site_action                       :integer
#  special                           :boolean          default(FALSE), not null
#  stock                             :integer
#  ticket_cost                       :decimal(6, 2)
#  type                              :string
#  under_the_fold_description        :text
#  unlock_on                         :date
#  usd_cost                          :decimal(6, 2)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  idx_shop_items_enabled_black_market_price  (enabled,requires_black_market,ticket_cost)
#  idx_shop_items_regional_enabled            (enabled,enabled_us,enabled_eu,enabled_in,enabled_ca,enabled_au,enabled_xx)
#  idx_shop_items_type_enabled                (type,enabled)
#  index_shop_items_on_unlock_on              (unlock_on)
#
class ShopItem::AdventSticker < ShopItem
  has_one_attached :silhouette_image

  validates :unlock_on, presence: true
  before_destroy :prevent_delete_if_awarded

  before_validation :set_ticket_cost_to_zero, on: :create

  scope :unlocked, ->(date = Date.current) { where("unlock_on <= ?", date) }
  scope :today, -> { where(unlock_on: Date.current) }
  scope :specials, -> { where(special: true) }
  scope :regulars, -> { where(special: false) }

  def campfire_only? = campfire_only

  private

  def set_ticket_cost_to_zero
    self.ticket_cost = 0
  end

  def prevent_delete_if_awarded
    if UserAdventSticker.exists?(shop_item_id: id)
      errors.add(:base, "Cannot delete an Advent sticker that has been awarded")
      throw :abort
    end
  end
end
