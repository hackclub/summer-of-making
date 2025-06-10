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
class ShopItem::SpecialFulfillmentItem < ShopItem
end
