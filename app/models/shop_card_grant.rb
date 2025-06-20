class ShopCardGrant < ApplicationRecord
  belongs_to :user
  belongs_to :shop_item
end
