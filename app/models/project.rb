# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                     :bigint           not null, primary key
#  category               :string
#  certification_type     :integer
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
#  views_count            :integer          default(0), not null
#  ysws_submission        :boolean          default(FALSE), not null
#  ysws_type              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_projects_on_user_id      (user_id)
#  index_projects_on_views_count  (views_count)
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

  has_many :won_votes, class_name: "Vote", foreign_key: "winning_project_id"
  has_many :vote_changes, dependent: :destroy

  has_many :timer_sessions

  default_scope { where(is_deleted: false) }

  scope :with_ship_event, -> { joins(:ship_events) }

  def self.with_deleted
    unscoped
  end

  scope :pending_certification, -> {
    joins(:ship_certifications).where(ship_certifications: { judgement: "pending" })
  }

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 2500 }
  validates :category, presence: true

  validates :readme_link, :demo_link, :repo_link,
            format: { with: /\A(?:https?:\/\/).*\z/i, message: "must be a valid HTTP or HTTPS URL" },
            allow_blank: true

  validate :link_check

  before_save :convert_github_blob_urls

  CATEGORIES = [ "Web App", "Mobile App", "Command Line Tool", "Video Game", "Something else" ]
  validates :category, inclusion: { in: CATEGORIES, message: "%<value>s is not a valid category" }

  enum :certification_type, {
    cert_other: 0,
    static_site: 1,
    web_app: 2,
    browser_extension: 3,
    userscript: 4,
    iphone_app: 5,
    android_app: 6,
    desktop_app: 7,
    command_line_tool: 8,
    game_mod: 9,
    chat_bot: 10,
    video: 11,
    hardware_or_pcb_project: 12
  }

  enum :ysws_type, {
    athena: "Athena",
    boba_drops: "Boba Drops",
    cider: "Cider",
    converge: "Converge (Discord/Slackbot YSWS)",
    grub: "Grub",
    hackaccino: "Hackaccino",
    highway: "Highway",
    jumpstart: "Jumpstart",
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
  before_save :set_default_certification_type

  def total_votes
    vote_changes.count
  end

  def wins_count
    vote_changes.wins.count
  end

  def losses_count
    vote_changes.losses.count
  end

  def ties_count
    vote_changes.ties.count
  end

  def current_elo_rating
    rating
  end

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
      },
      previous_payout: {
        met: latest_ship_certification&.rejected? || unpaid_shipevents_since_last_payout.empty?,
        message: "Previous ship event must be paid out before shipping again."
      },
      minimum_time: {
        met: ship_events.empty? || devlogs_since_last_ship.sum(:seconds_coded) >= 3600,
        message: "Project must have at least 1 hour of tracked time since last ship."
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

  def unpaid_shipevents_since_last_payout
    ShipEvent.where(project: self)
             .left_joins(:payouts)
             .where(payouts: { id: nil })
             .order("ship_events.created_at")
  end

  def self.cumulative_elo_bounds_at_vote_count(count)
    votes = VoteChange.where("project_vote_count <= ?", count)

    col = :elo_after
    [ votes.minimum(col), votes.maximum(col) ]
  end

  def calculate_payout
    vote_count = VoteChange.where(project: self).maximum(:project_vote_count)
    min, max = Project.cumulative_elo_bounds_at_vote_count vote_count

    pc = unlerp(min, max, rating)

    mult = Payout.calculate_multiplier pc

    puts "mult", mult

    hours = devlogs.sum(:seconds_coded).fdiv(3600)
    puts "hours", hours

    payout = hours * mult
  end

  def issue_payouts
    ship_events.each_with_index do |ship, idx|
      next_ship_created_at = ship_events[idx + 1]&.created_at || Float::INFINITY
      changes = vote_changes.where("created_at < ?", next_ship_created_at).where("project_vote_count <= ?", Payout::VOTE_COUNT_REQUIRED)

      next if changes.count < Payout::VOTE_COUNT_REQUIRED

      min, max = Project.cumulative_elo_bounds_at_vote_count Payout::VOTE_COUNT_REQUIRED

      rating_at_vote_count = changes.last.elo_after
      pc = unlerp(min, max, rating_at_vote_count)

      puts "FKDF", pc, min, max, rating_at_vote_count

      mult = Payout.calculate_multiplier pc

      hours = ship.hours_covered

      amount = (mult * hours).ceil

      current_payout_sum = ship.payouts.sum(:amount)
      current_payout_difference = amount - current_payout_sum

      next if current_payout_difference.zero?

      reason = "Payout#{" recalculation" if ship.payouts.count > 0} for #{title}'s #{ship.created_at} ship."

      payout = Payout.create!(amount: current_payout_difference, payable: ship, user:, reason:)

      puts "PAYOUTCREASED(#{payout.id}) ship.id:#{ship.id} min:#{min} max:#{max} rating_at_vote_count:#{rating_at_vote_count} pc:#{pc} mult:#{mult} hours:#{hours} amount:#{amount} current_payout_sum:#{current_payout_sum} current_payout_difference:#{current_payout_difference}"
    end
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

  def unlerp(start, stop, value)
    return 0.0 if start == stop
    (value - start) / (stop - start).to_f
  end

  def set_default_certification_type
    self.certification_type = :cert_other if certification_type.blank?
  end

  private

  def convert_github_blob_urls
    convert_github_blob_url_for(:readme_link)
    convert_github_blob_url_for(:repo_link) if repo_link.present? && readme_link.blank?
  end

  def convert_github_blob_url_for(field)
    url = send(field)
    return if url.blank?

    converted_url = self.class.convert_github_blob_to_raw(url)
    send("#{field}=", converted_url) if converted_url != url
  end

  def self.convert_github_blob_to_raw(url)
    return url if url.blank?

    if match = url.match(%r{^https://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$})
      owner, repo, branch, file_path = match.captures
      "https://raw.githubusercontent.com/#{owner}/#{repo}/refs/heads/#{branch}/#{file_path}"
    else
      url
    end
  end

  private

  def link_check
    urls = [ readme_link, demo_link, repo_link ]
    urls.each do |url|
      next if url.blank?
      begin
        uri = URI.parse(url)
        host = uri.host
        if host =~ /^(localhost|127\.0\.0\.1|::1)$/i || host =~ /^(\d{1,3}\.){3}\d{1,3}$/
          errors.add(:base, "We can not accept that type of link!")
        end
      rescue URI::InvalidURIError
        # other things will handle this
      end
    end
  end
end
