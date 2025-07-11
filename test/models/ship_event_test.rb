# == Schema Information
#
# Table name: ship_events
#
#  id            :bigint           not null, primary key
#  shells_earned :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  project_id    :bigint           not null
#
# Indexes
#
#  index_ship_events_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
require "test_helper"

class ShipEventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
