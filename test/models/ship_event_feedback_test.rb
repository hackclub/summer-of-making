# == Schema Information
#
# Table name: ship_event_feedbacks
#
#  id            :bigint           not null, primary key
#  comment       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ship_event_id :bigint           not null
#
# Indexes
#
#  index_ship_event_feedbacks_on_ship_event_id  (ship_event_id)
#
# Foreign Keys
#
#  fk_rails_...  (ship_event_id => ship_events.id)
#
require "test_helper"

class ShipEventFeedbackTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
