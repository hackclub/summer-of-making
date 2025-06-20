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
class ShipEventFeedback < ApplicationRecord
  belongs_to :ship_event
  has_one_attached :demo, dependent: :destroy
end
