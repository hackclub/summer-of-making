# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                     :bigint           not null, primary key
#  category               :string
#  demo_link              :string
#  description            :text
#  hackatime_project_keys :string           default([]), is an Array
#  is_deleted             :boolean          default(FALSE)
#  is_shipped             :boolean          default(FALSE)
#  rating                 :integer
#  readme_link            :string
#  repo_link              :string
#  title                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_projects_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Project < ApplicationRecord
  belongs_to :user
  has_many :devlogs
  has_many :project_follows
  has_many :followers, through: :project_follows, source: :user
  has_many :stonks
  has_many :stakers, through: :stonks, source: :user
  has_many :ship_events
  has_one :stonk_tickler
  has_one_attached :banner

  has_many :won_votes, class_name: "Vote", foreign_key: "winner_id"
  has_many :lost_votes, class_name: "Vote", foreign_key: "loser_id"

  has_many :timer_sessions

  default_scope { where(is_deleted: false) }

  def self.with_deleted
    unscoped
  end

  def self.find_with_deleted(id)
    with_deleted.find(id)
  end

  validates :title, :description, :category, presence: true

  validates :readme_link, :demo_link, :repo_link,
            format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" },
            allow_blank: true

  validates :category,
            inclusion: { in: [ "Software", "Hardware", "Both Software & Hardware", "Something else" ],
                         message: "%<value>s is not a valid category" }

  validate :cannot_change_category, on: :update
  validate :user_must_have_hackatime, on: :create

  after_initialize :set_default_rating, if: :new_record?
  before_save :filter_hackatime_keys

  before_save :remove_duplicate_hackatime_keys

  after_commit :sync_to_airtable, on: %i[create update]

  def total_votes
    won_votes.count + lost_votes.count
  end

  delegate :count, to: :won_votes, prefix: true

  delegate :count, to: :lost_votes, prefix: true

  def hackatime_total_time
    return 0 unless user.has_hackatime? && hackatime_project_keys.present?

    hackatime_project_keys.sum do |project_key|
      user.project_time_from_hackatime(project_key)
    end
  end

  def total_stonks
    stonks.sum(:amount)
  end

  def user_stonks(user)
    stonk = stonks.find_by(user: user)
    stonk ? stonk.amount : 0
  end

  def hackatime_keys
    hackatime_project_keys || []
  end

  def cumulative_stonk_dollars
    stonk_dollars_by_day = stonks.group_by_day(:created_at).sum(:amount)

    stonk_dollars_by_day.each_with_object({}) do |(date, count), result|
      previous = result.empty? ? 0 : result.values.last
      result[date] = previous + count
    end
  end

  def create_tickler
    StonkTickler.create(project: self)
  end

  def devlogs_since_last_ship
    last_ship_event_time = ship_events.order(:created_at).last&.created_at
    last_ship_event_time.nil? ? devlogs : devlogs.where("created_at > ?", last_ship_event_time)
  end

  def shipping_requirements
    {
      devlogs: {
        met: devlogs_since_last_ship.count >= 1,
        message: "You must have at least one devlog #{ship_events.count > 0 ? "since the last ship" : ""}"
      },
      repo_link: {
        met: repo_link.present?,
        message: "Project must have a repository link."
      },
      readme_link: {
        met: readme_link.present? && readme_link.include?("raw"),
        message: "Project must have a raw GitHub documentation link."
      },
      demo_link: {
        met: demo_link.present?,
        message: "Project must have a demo link."
      },
      description: {
        met: description.present? && description.length >= 30,
        message: "Project must have a valid description (at least 30 characters)."
      },
      banner: {
        met: banner.present?,
        message: "Project must have a banner image."
      }
    }
  end

  def shipping_errors
    shipping_requirements.filter_map { |_key, req| req[:message] unless req[:met] }
  end

  def can_ship?
    shipping_requirements.all? { |_key, req| req[:met] }
  end

  private

  def set_default_rating
    self.rating ||= 1100
  end

  def cannot_change_category
    return unless category_changed? && persisted?

    errors.add(:category, "cannot be changed after project creation")
  end

  def user_must_have_hackatime
    return if user&.has_hackatime?

    errors.add(:base, "You must link your HackaTime account before creating a project")
  end

  def filter_hackatime_keys
    self.hackatime_project_keys = hackatime_project_keys.compact_blank if hackatime_project_keys
  end

  def remove_duplicate_hackatime_keys
    self.hackatime_project_keys = hackatime_project_keys.uniq if hackatime_project_keys
  end

  def sync_to_airtable
    SyncProjectToAirtableJob.perform_later(id)
  end
end
