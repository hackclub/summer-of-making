# == Schema Information
#
# Table name: user_badges
#
#  id         :bigint           not null, primary key
#  badge_key  :string           not null
#  earned_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_badges_on_badge_key              (badge_key)
#  index_user_badges_on_user_id                (user_id)
#  index_user_badges_on_user_id_and_badge_key  (user_id,badge_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserBadge < ApplicationRecord
  belongs_to :user

  validates :badge_key, presence: true, uniqueness: { scope: :user_id }
  validates :earned_at, presence: true
  validate :badge_key_exists

  def badge_definition
    Badge.find(badge_key)
  end

  private

  def badge_key_exists
    errors.add(:badge_key, "is not a valid badge") unless Badge.exists?(badge_key)
  end
end
