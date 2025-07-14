# == Schema Information
#
# Table name: ship_events
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :bigint           not null
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

  after_create :maybe_create_ship_certification
  after_create :award_user_badges

  def user
    project.user
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

  def award_user_badges
    user.award_badges_async!("ship_event_created")
  end
end
