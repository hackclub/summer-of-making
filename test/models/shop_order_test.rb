# == Schema Information
#
# Table name: shop_orders
#
#  id                                 :bigint           not null, primary key
#  aasm_state                         :string
#  awaiting_periodical_fulfillment_at :datetime
#  external_ref                       :string
#  frozen_address                     :jsonb
#  frozen_item_price                  :decimal(6, 2)
#  fulfilled_at                       :datetime
#  internal_notes                     :text
#  on_hold_at                         :datetime
#  quantity                           :integer
#  rejected_at                        :datetime
#  rejection_reason                   :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  shop_card_grant_id                 :bigint
#  shop_item_id                       :bigint           not null
#  user_id                            :bigint           not null
#
# Indexes
#
#  index_shop_orders_on_shop_card_grant_id  (shop_card_grant_id)
#  index_shop_orders_on_shop_item_id        (shop_item_id)
#  index_shop_orders_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shop_card_grant_id => shop_card_grants.id)
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ShopOrderTest < ActiveSupport::TestCase
end
