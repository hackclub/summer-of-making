# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_items
#
#  id                    :bigint           not null, primary key
#  agh_contents          :jsonb
#  description           :string
#  hacker_score          :integer          default(0)
#  hcb_category_lock     :string
#  hcb_keyword_lock      :string
#  hcb_merchant_lock     :string
#  internal_description  :string
#  limited               :boolean          default(FALSE)
#  max_qty               :integer          default(10)
#  name                  :string
#  one_per_person_ever   :boolean          default(FALSE)
#  requires_black_market :boolean
#  show_in_carousel      :boolean
#  stock                 :integer
#  ticket_cost           :decimal(6, 2)
#  type                  :string
#  usd_cost              :decimal(6, 2)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class ShopItem < ApplicationRecord
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 256, 256 ]
  end

  has_many :shop_orders

  scope :black_market, -> { where(requires_black_market: true) }
  scope :not_black_market, -> { where(requires_black_market: [ false, nil ]) }
  scope :shown_in_carousel, -> { where(show_in_carousel: true) }

  validates_presence_of :ticket_cost, :name, :description

  def manually_fulfilled?
    true
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

  def remaining_stock
    return nil unless limited? && stock.present?
    ordered_quantity = shop_orders.worth_counting.sum(:quantity)
    stock - ordered_quantity
  end

  def out_of_stock?
    limited? && remaining_stock && remaining_stock <= 0
  end
end
