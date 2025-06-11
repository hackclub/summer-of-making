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
#  max_qty               :integer          default(10)
#  name                  :string
#  one_per_person_ever   :boolean          default(FALSE)
#  requires_black_market :boolean
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

  scope :black_market, -> { where(requires_black_market: true) }
  scope :not_black_market, -> { where(requires_black_market: [ false, nil ]) }

  def manually_fulfilled?
    true
  end

  def can_afford?(user)
    user.balance >= self.ticket_cost
  end
end
