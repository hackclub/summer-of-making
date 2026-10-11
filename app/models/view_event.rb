# frozen_string_literal: true

# == Schema Information
#
# Table name: view_events
#
#  id            :bigint           not null, primary key
#  ip_address    :string
#  user_agent    :string
#  viewable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint
#  viewable_id   :bigint           not null
#
# Indexes
#
#  idx_on_viewable_type_viewable_id_created_at_95fa2a7c9e  (viewable_type,viewable_id,created_at)
#  index_view_events_on_created_at                         (created_at)
#  index_view_events_on_user_id                            (user_id)
#  index_view_events_on_viewable                           (viewable_type,viewable_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class ViewEvent < ApplicationRecord
  belongs_to :viewable, polymorphic: true
  belongs_to :user, optional: true

  validates :viewable, presence: true
  validates :ip_address, presence: true, if: -> { user_id.blank? }

  scope :for_projects, -> { where(viewable_type: "Project") }
  scope :for_devlogs, -> { where(viewable_type: "Devlog") }
  scope :recent, ->(days = 30) { where(created_at: days.days.ago..Time.current) }
  scope :by_date, -> { group_by_day(:created_at) }

  def self.daily_counts(days = 30)
    recent(days).by_date.count
  end

  def self.daily_counts_by_type(days = 30)
    recent(days).group(:viewable_type).by_date.count
  end
end
