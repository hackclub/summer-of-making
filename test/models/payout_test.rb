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
require "test_helper"

class PayoutTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
