# == Schema Information
#
# Table name: ship_reviewer_payout_requests
#
#  id              :bigint           not null, primary key
#  amount          :decimal(, )
#  approved_at     :datetime
#  decisions_count :integer
#  requested_at    :datetime
#  status          :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  approved_by_id  :bigint
#  reviewer_id     :bigint           not null
#
# Indexes
#
#  index_ship_reviewer_payout_requests_on_approved_by_id  (approved_by_id)
#  index_ship_reviewer_payout_requests_on_reviewer_id     (reviewer_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (reviewer_id => users.id)
#
require "test_helper"

class ShipReviewerPayoutRequestTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
