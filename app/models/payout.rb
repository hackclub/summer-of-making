# == Schema Information
#
# Table name: payouts
#
#  id           :bigint           not null, primary key
#  amount       :decimal(6, 2)
#  payable_type :string
#  reason       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  payable_id   :bigint
#  user_id      :bigint           not null
#
# Indexes
#
#  index_payouts_on_payable  (payable_type,payable_id)
#  index_payouts_on_user_id  (user_id)
#
class Payout < ApplicationRecord
  belongs_to :payable, polymorphic: true
  belongs_to :user

  validates_presence_of :amount

  before_validation :set_user_id

  private

  def set_user_id
    self.user ||= payable.is_a?(User) ? payable : payable.user
  end
end
