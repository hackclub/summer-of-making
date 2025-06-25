# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                     :bigint           not null, primary key
#  category               :string
#  demo_link              :string
#  description            :text
#  devlogs_count          :integer          default(0), not null
#  hackatime_project_keys :string           default([]), is an Array
#  is_deleted             :boolean          default(FALSE)
#  is_shipped             :boolean          default(FALSE)
#  rating                 :integer
#  readme_link            :string
#  repo_link              :string
#  title                  :string
#  used_ai                :boolean
#  ysws_submission        :boolean          default(FALSE), not null
#  ysws_type              :string
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

  has_many :ship_certifications
  has_many :readme_certifications

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

  scope :pending_certification, -> {
    joins(:ship_certifications).where(ship_certifications: { judgement: "pending" })
  }

  validates :title, :description, :category, presence: true

  validates :readme_link, :demo_link, :repo_link,
            format: { with: /\A(?:https?:\/\/).*\z/i, message: "must be a valid HTTP or HTTPS URL" },
            allow_blank: true

  validates :category,
            inclusion: { in: [ "Web App", "Mobile App", "Command Line Tool", "Video Game", "Something else" ],
                         message: "%<value>s is not a valid category" }

  enum :ysws_type, {
    athena: "Athena",
    boba_drops: "Boba Drops",
    cider: "Cider",
    grub: "Grub",
    hackaccino: "Hackaccino",
    highway: "Highway",
    neighborhood: "Neighborhood",
    shipwrecked: "Shipwrecked",
    solder: "Solder",
    sprig: "Sprig",
    swirl: "Swirl",
    terminalcraft: "Terminalcraft",
    thunder: "Thunder",
    tonic: "Tonic",
    toppings: "Toppings",
    waffles: "Waffles",
    waveband: "Waveband",
    fixit: "FIX IT!",
    twist: "Twist",
    other: "Other"
  }

  validates :ysws_type, presence: true, if: :ysws_submission?

  validate :user_must_have_hackatime, on: :create

  after_initialize :set_default_rating, if: :new_record?
  after_update :maybe_create_readme_certification
  before_save :filter_hackatime_keys

  before_save :remove_duplicate_hackatime_keys

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

  has_many :readme_checks, dependent: :destroy
  def check_readme!
    readme_checks.pending.first || ReadmeCheck.create(project: self)
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

  def latest_ship_certification
    @latest_ship_certification ||= ship_certifications.order(created_at: :desc).first
  end

  def certification_status
    latest_ship_certification.judgement
  end

  def certification_status_text
    case certification_status
    when "pending"
      "awaiting ship certification"
    when "approved"
      "ship certified"
    when "rejected"
      "no ship certification"
    else
      nil
    end
  end

  def certification_visible_to?(user)
    return false unless latest_ship_certification

    return true if latest_ship_certification.approved?

    return true if user && (user == self.user || user.is_admin?)

    false
  end

  def self.cumulative_elo_bounds_at_vote_count count
    [100, 2000]
  end

  def calculate_payout
    min, max = Project.cumulative_elo_bounds_at_vote_count 1

    pc = unlerp(min, max, rating)

    mult = Payout.calculate_multiplier pc

    puts "mult", mult

    hours = devlogs.sum(:seconds_coded).fdiv(3600)

    payout = hours * mult
  end

  private

  def set_default_rating
    self.rating ||= 1100
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

  def maybe_create_readme_certification
    return unless saved_change_to_readme_link?
    return if readme_link.blank?
    return if readme_certifications.exists?

    readme_certifications.create!
  end
end
