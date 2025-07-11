# == Schema Information
#
# Table name: ship_events
#
#  id          :bigint           not null, primary key
#  votes_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
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
  belongs_to :project
  has_one :ship_event_feedback
  has_many :payouts, as: :payable
  has_many :votes_as_ship_event_1, class_name: "Vote", foreign_key: "ship_event_1_id"
  has_many :votes_as_ship_event_2, class_name: "Vote", foreign_key: "ship_event_2_id"

  after_create :maybe_create_ship_certification

  def user
    project.user
  end

  def votes
    Vote.where("ship_event_1_id = ? OR ship_event_2_id = ?", id, id)
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
    devlogs_since_last.sum(:duration_seconds)
  end
  # this is the hours covered by the ship event, not the total hours up to the ship event
  def hours_covered
    seconds_covered.fdiv(3600)
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
end
