# == Schema Information
#
# Table name: user_advent_stickers
#
#  id           :bigint           not null, primary key
#  earned_on    :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  devlog_id    :bigint           not null
#  shop_item_id :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_advent_stickers_on_devlog_id                 (devlog_id)
#  index_user_advent_stickers_on_earned_on                 (earned_on)
#  index_user_advent_stickers_on_shop_item_id              (shop_item_id)
#  index_user_advent_stickers_on_user_id                   (user_id)
#  index_user_advent_stickers_on_user_id_and_shop_item_id  (user_id,shop_item_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (devlog_id => devlogs.id)
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (user_id => users.id)
#
class UserAdventSticker < ApplicationRecord
  belongs_to :user
  belongs_to :shop_item, class_name: "ShopItem::AdventSticker"
  belongs_to :devlog

  validates :earned_on, presence: true
end
