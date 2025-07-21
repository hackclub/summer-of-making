# frozen_string_literal: true

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
class ShopItem < ApplicationRecord
  include Shop::Regionalizable

  def self.fulfill_immediately?
    false
  end

  MANUAL_FULFILLMENT_TYPES = [
    ShopItem::ThirdPartyPhysical,
    ShopItem::HQMailItem,
    ShopItem::SpecialFulfillmentItem
  ]

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 256, 256 ]
  end

  has_many :shop_orders

  scope :black_market, -> { where(requires_black_market: true) }
  scope :not_black_market, -> { where(requires_black_market: [ false, nil ]) }
  scope :shown_in_carousel, -> { where(show_in_carousel: true) }
  scope :manually_fulfilled, -> { where(type: MANUAL_FULFILLMENT_TYPES) }
  scope :enabled, -> { where(enabled: true) }

  def fulfill!(shop_order)
    shop_order.queue_for_nightly
    shop_order.save!
  end

  validates_presence_of :ticket_cost, :name, :description
  def manually_fulfilled?
    MANUAL_FULFILLMENT_TYPES.include? self.class
  end

  def can_afford?(user)
    user.balance >= self.ticket_cost
  end

  def is_free?
    self.ticket_cost.zero?
  end

  def average_hours_estimated
    return 0 unless ticket_cost.present?
    ticket_cost / (Rails.configuration.game_constants.tickets_per_dollar * Rails.configuration.game_constants.dollars_per_mean_hour)
  end

  def hours_estimated
    average_hours_estimated.to_i
  end

  def fixed_estimate(price)
    return 0 unless price.present? && price > 0
    price / (Rails.configuration.game_constants.tickets_per_dollar * Rails.configuration.game_constants.dollars_per_mean_hour)
  end

  def remaining_stock
    return nil unless limited? && stock.present?
    ordered_quantity = shop_orders.worth_counting.sum(:quantity)
    stock - ordered_quantity
  end

  def out_of_stock?
    limited? && remaining_stock && remaining_stock <= 0
  end
end
