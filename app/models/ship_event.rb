# == Schema Information
#
# Table name: ship_events
#
#  id            :bigint           not null, primary key
#  for_sinkening :boolean          default(FALSE), not null
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
class ShipEvent < ApplicationRecord
  include AirtableSyncable
  include Balloonable

  belongs_to :project
  has_one :user, through: :project
  has_one :ship_event_feedback
  has_many :payouts, as: :payable

  after_create :maybe_create_ship_certification
  after_create :award_user_badges

  def self.airtable_table_name
    "_ship_events"
  end

  def self.airtable_field_mappings
    {
      "duration_seconds" => "seconds_covered",
      "_projects" => "airtable_project_record_ids"
    }
  end

  def airtable_project_record_ids
    return [] unless project.airtable_synced?
    [ project.airtable_record_id ]
  end

  def devlogs_since_last
    previous_ships = ShipEvent.where(project: project)
                              .where("created_at < ?", created_at)
                              .order(:created_at)


    if previous_ships.empty?
      Devlog.where(project: project).where("created_at < ?", created_at)
    else
      last_ship_date = previous_ships.last.created_at
      Devlog.where(project: project)
            .where("created_at > ? AND created_at < ?", last_ship_date, created_at)
    end
  end

  def seconds_covered
    devlogs_since_last.capped_duration_seconds
  end
  # this is the hours covered by the ship event, not the total hours up to the ship event
  def hours_covered
    hours = seconds_covered.fdiv(3600)
    if created_at >= Time.new(2025, 7, 19)
      [ hours, 10 ].min
    else
      hours
    end
  end

  # this is the total hours up to the ship event
  def total_time_up_to_ship
    Devlog.where(project: project)
          .where("created_at <= ?", created_at)
          .sum(:duration_seconds)
  end

  private

  def maybe_create_ship_certification
    return if project.ship_certifications.approved.exists?
    return if project.ship_certifications.pending.exists?

    project.ship_certifications.create!
  end

  def award_user_badges
    user.award_badges_async!("ship_event_created")
  end
end
