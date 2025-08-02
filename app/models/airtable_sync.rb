# == Schema Information
#
# Table name: airtable_syncs
#
#  id                 :bigint           not null, primary key
#  last_synced_at     :datetime
#  syncable_type      :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  airtable_record_id :string
#  syncable_id        :bigint           not null
#
# Indexes
#
#  index_airtable_syncs_on_last_synced_at                 (last_synced_at)
#  index_airtable_syncs_on_syncable                       (syncable_type,syncable_id)
#  index_airtable_syncs_on_syncable_type_and_syncable_id  (syncable_type,syncable_id) UNIQUE
#
class AirtableSync < ApplicationRecord
  belongs_to :syncable, polymorphic: true

  %w[Project ShipEvent YswsReview::Submission].each do |syncable_type|
    scope :"for_#{syncable_type.underscore}", -> { where(syncable_type: syncable_type) }
  end
  scope :oldest_synced, -> { order("last_synced_at ASC NULLS FIRST") }

  def self.mark_synced!
    update_all(last_synced_at: Time.current)
  end

  def mark_synced!
    update!(last_synced_at: Time.current)
  end
end
