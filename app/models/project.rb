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
#  is_sinkening_ship      :boolean          default(FALSE)
#  rating                 :integer
#  readme_link            :string
#  repo_link              :string
#  title                  :string
#  used_ai                :boolean
#  views_count            :integer          default(0), not null
#  x                      :float
#  y                      :float
#  ysws_submission        :boolean          default(FALSE), not null
#  ysws_type              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_projects_on_is_shipped   (is_shipped)
#  index_projects_on_user_id      (user_id)
#  index_projects_on_views_count  (views_count)
#  index_projects_on_x_and_y      (x,y)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Project < ApplicationRecord
  has_paper_trail

  include PublicActivity::Model

  belongs_to :user
  has_many :devlogs
  has_many :project_follows
  has_many :followers, through: :project_follows, source: :user
  has_many :stonks
  has_many :stakers, through: :stonks, source: :user
  has_many :ship_events
  has_one :stonk_tickler
  has_one_attached :banner

  include AirtableSyncable

  def self.airtable_table_name
    "_projects"
  end

  def self.airtable_field_mappings
    {
      "_ship_events" => "airtable_ship_event_record_ids"
    }
  end

  def airtable_ship_event_record_ids
    ship_events.joins(:airtable_sync)
               .where.not(airtable_syncs: { airtable_record_id: nil })
               .pluck("airtable_syncs.airtable_record_id")
  end

  has_many :ship_certifications
  has_many :readme_certifications
  has_many :shipwright_advices, class_name: "ShipwrightAdvice"

  has_many :won_votes, class_name: "Vote", foreign_key: "winning_project_id"
  has_many :vote_changes, dependent: :destroy

  has_many :timer_sessions

  coordinate_min = 0
  coordinate_max = 100

  validates :x, numericality: { greater_than_or_equal_to: coordinate_min, less_than_or_equal_to: coordinate_max }, allow_nil: true
  validates :y, numericality: { greater_than_or_equal_to: coordinate_min, less_than_or_equal_to: coordinate_max }, allow_nil: true
  validate :coordinates_must_be_set_together

  scope :on_map, -> { where.not(x: nil, y: nil) }
  scope :shipped, -> { where(is_shipped: true) }
  scope :not_on_map, -> { where(x: nil, y: nil) }

  def shipped_once?
    ship_events.any?
  end

  def coordinates_must_be_set_together
    if (x.present? && y.blank?) || (y.present? && x.blank?)
      errors.add(:base, "Both X and Y coordinates must be set, or neither.")
    end
  end

  default_scope { where(is_deleted: false) }

  scope :with_ship_event, -> { joins(:ship_events) }

  def self.with_deleted
    unscope(where: :is_deleted)
  end

  scope :pending_certification, -> {
    joins(:ship_certifications).where(ship_certifications: { judgement: "pending" })
  }

  # Projects eligible for YSWS review
  scope :ysws_review_eligible, -> {
    joins(:ship_certifications)
      .where(ship_certifications: { judgement: "approved" })
      .where(ysws_type: nil)
      .where(is_deleted: false)
  }

  has_one :ysws_review_submission, class_name: "YswsReview::Submission", dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 2500 }


  validates :readme_link, :demo_link, :repo_link,
            format: { with: /\A(?:https?:\/\/).*\z/i, message: "must be a valid HTTP or HTTPS URL" },
            allow_blank: true

  validate :link_check

  before_save :convert_github_blob_urls

  CATEGORIES = [ "Web App", "Mobile App", "Command Line Tool", "Video Game", "Something else" ]
  validates :category, inclusion: { in: CATEGORIES, message: "%<value>s is not a valid category" }, allow_blank: true

  attribute :certification_type, :integer

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

  attribute :ysws_type, :string

  enum :ysws_type, {
    athena: "Athena",
    boba_drops: "Boba Drops",
    cider: "Cider",
    cmdk: "cmd + k",
    converge: "Converge",
    grub: "Grub",
    hackaccino: "Hackaccino",
    hackcraft: "Hackcraft",
    highway: "Highway",
    jumpstart: "Jumpstart",
    neighborhood: "Neighborhood",
    railway: "Railway",
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
    reality: "Reality",
    endpointer: "Endpointer",
    other: "Other"
  }

  validates :ysws_type, presence: true, if: :ysws_submission?

  validate :user_must_have_hackatime, on: :create
  validate :cannot_remove_locked_hackatime_keys, on: :update
  validate :cannot_assign_globally_locked_hackatime_keys

  after_initialize :set_default_rating, if: :new_record?
  after_update :maybe_create_readme_certification
  before_save :filter_hackatime_keys

  before_save :remove_duplicate_hackatime_keys

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

  def total_seconds_coded
    if devlogs.loaded?
      devlogs.sum(&:duration_seconds)
    else
      devlogs.sum(:duration_seconds)
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

  def coding_time
    return 0 unless user.has_hackatime? && hackatime_keys.present?

    user.user_hackatime_data&.total_seconds_for_project(self) || 0
  end

  def can_post_devlog?(required_seconds = 300)
    return false unless user.has_hackatime? && hackatime_keys.present?

    if has_neighborhood_migrated_devlogs?
      total_hackatime = user.user_hackatime_data&.fetch_neighborhood_total_time(hackatime_keys) || 0
      unlogged = [ total_hackatime - total_seconds_coded, 0 ].max
    else
      unlogged = unlogged_time
    end

    unlogged >= required_seconds
  end

  def unlogged_time
    [ coding_time - total_seconds_coded, 0 ].max
  end

  def has_neighborhood_migrated_devlogs?
    devlogs.where(is_neighborhood_migrated: true).exists?
  end

  def locked_hackatime_keys
    return [] unless persisted?

    keys_in_devlogs = devlogs.where.not(hackatime_projects_key_snapshot: [])
                             .pluck(:hackatime_projects_key_snapshot)
                             .flatten
                             .uniq

    hackatime_keys & keys_in_devlogs
  end

  def self.globally_locked_hackatime_keys(user_id = nil)
    query = Devlog.joins(:project)
                  .where(projects: { is_deleted: false })
                  .where.not(hackatime_projects_key_snapshot: [])
    query = query.joins(:user).where(user_id: user_id) if user_id
    query.pluck(:hackatime_projects_key_snapshot)
         .flatten
         .uniq
  end

  def self.hackatime_key_locked_globally?(key, user_id = nil)
    globally_locked_hackatime_keys(user_id).include?(key)
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
      voting_quota: {
        met: user.votes_since_last_ship_count >= 20,
        message: "You must vote #{user.remaining_votes_to_ship} more times to ship."
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
        message: "Project must have a banner image (not from a Devlog)."
      },
      previous_payout: {
        met: unpaid_ship_events_since_last_payout.empty?,
        message: "Previous ship event must be paid out before shipping again."
      },
      minimum_time: {
        met: ship_events.empty? || devlogs_since_last_ship.sum(:duration_seconds) >= 3600,
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
      "Awaiting ship certification..."
    when "approved"
      "Ship certified"
    when "rejected"
      "Changes needed"
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

  def can_request_recertification?
    latest_ship_certification&.rejected? &&
    ship_events.any? &&
    !latest_ship_certification.pending?
  end

  def request_recertification!
    return false unless can_request_recertification?

    # create a new pending ship certification
    ship_certifications.create!(judgement: :pending)
  end

  def unpaid_ship_events_since_last_payout
    @unpaid_ship_events_since_last_payout ||= ShipEvent.where(project: self)
                                                      .left_joins(:payouts)
                                                      .where(payouts: { id: nil })
  end

  def issue_genesis_payouts
    project_vote_count = VoteChange.where(project: self).count

    ship_events.each_with_index do |ship, idx|
      ship_event_vote_count = VoteChange.where(project: self).where("created_at > ?", ship.created_at).count

      # Only process ship events that have 18 or more votes
      next unless ship_event_vote_count >= 18

      # Calculate cumulative vote count for this ship event payout
      votes_before_ship = VoteChange.where(project: self).where("created_at <= ?", ship.created_at).count
      cumulative_vote_count_at_payout = votes_before_ship + 18

      puts "Ship #{ship.id} created at #{ship.created_at}: votes_before=#{votes_before_ship}, cumulative=#{cumulative_vote_count_at_payout}"

      # Find when this ship event got its 18th vote
      # This is when votes_before_ship + votes after ship creation = cumulative_vote_count_at_payout
      ship_votes_needed = 18
      target_vote_count = votes_before_ship + ship_votes_needed

      # Get the project's ELO rating when it reached this target vote count
      vote_change_at_target = VoteChange.where(project: self, project_vote_count: target_vote_count).first

      if vote_change_at_target
        current_rating = vote_change_at_target.elo_after

        # Genesis: use cumulative range up to this vote count (no time filtering)
        min, max = VoteChange.cumulative_elo_range_for_vote_count(cumulative_vote_count_at_payout)

        next if min.nil? || max.nil?

        # Check if this project's ELO at this vote count is included in the cumulative range
        all_elos_at_count = VoteChange.where("project_vote_count <= ?", cumulative_vote_count_at_payout).pluck(:elo_after)
        project_vote_changes_in_range = VoteChange.where(project: self).where("project_vote_count <= ?", cumulative_vote_count_at_payout).pluck(:elo_after)
      else
        puts "ERROR: No VoteChange found for project #{id} at vote count #{target_vote_count}!"
        puts "Available vote counts for this project: #{VoteChange.where(project: self).pluck(:project_vote_count).sort}"
        # This should never happen!
        raise "ERROR: No VoteChange found for project #{id} at vote count #{target_vote_count}!"
      end

      pc = unlerp(min, max, current_rating)

      if pc < 0 || pc > 1
        raise "ERROR: Invalid percentile #{pc} for project #{id}. min=#{min}, max=#{max}, current_rating=#{current_rating}"
      end

      puts "FKDF", pc, min, max, current_rating

      mult = Payout.calculate_multiplier pc

      hours = ship.hours_covered

      amount = (mult * hours).ceil

      current_payout_sum = ship.payouts.sum(:amount)
      current_payout_difference = amount - current_payout_sum

      next if current_payout_difference.zero?

      reason = "Payout#{" recalculation" if ship.payouts.count > 0} for #{title}'s #{ship.created_at} ship."

      payout = Payout.create!(amount: current_payout_difference, payable: ship, user:, reason:, escrowed: false)

      puts "PAYOUTCREASED(#{payout.id}) ship.id:#{ship.id} min:#{min} max:#{max} rating_at_vote_count:#{current_rating} pc:#{pc} mult:#{mult} hours:#{hours} amount:#{amount} current_payout_sum:#{current_payout_sum} current_payout_difference:#{current_payout_difference}"
    end
  end

  def issue_payouts
    # NOTE Aug 23, 2025 IST: Escrow deprecated for new payouts.
    # Shipping is blocked until users reach the voting quota since last ship,
    # so payouts created here should not require escrow going forward. that said, we can escrow payouts at will if needed.
    return unless unpaid_ship_events_since_last_payout.any?

    project_vote_count = VoteChange.where(project: self).count

    unpaid_ship_events_since_last_payout.each_with_index do |ship, idx|
      ship_event_vote_count = VoteChange.where(project: self).where("created_at > ?", ship.created_at).count

      # Only process ship events that have exactly 18 votes
      next unless ship_event_vote_count == 18

      # Calculate cumulative vote count for this ship event payout
      votes_before_ship = VoteChange.where(project: self).where("created_at <= ?", ship.created_at).count
      cumulative_vote_count_at_payout = votes_before_ship + 18

      puts "Ship #{ship.id} created at #{ship.created_at}: votes_before=#{votes_before_ship}, cumulative=#{cumulative_vote_count_at_payout}"

      # Find when this ship event got its 18th vote
      # This is when votes_before_ship + votes after ship creation = cumulative_vote_count_at_payout
      ship_votes_needed = 18
      target_vote_count = votes_before_ship + ship_votes_needed

      # Get the project's ELO rating when it reached this target vote count
      vote_change_at_target = VoteChange.where(project: self, project_vote_count: target_vote_count).first

      if vote_change_at_target
        current_rating = vote_change_at_target.elo_after

        # Normal: use cumulative range up to this vote count AND created before the vote that triggered payout
        min, max = VoteChange.cumulative_elo_range_for_vote_count(cumulative_vote_count_at_payout, vote_change_at_target.created_at)

        next if min.nil? || max.nil?

        # Check if this project's ELO at this vote count is included in the cumulative range
        all_elos_at_count = VoteChange.where("project_vote_count <= ?", cumulative_vote_count_at_payout).pluck(:elo_after)
        project_vote_changes_in_range = VoteChange.where(project: self).where("project_vote_count <= ?", cumulative_vote_count_at_payout).pluck(:elo_after)
      else
        puts "ERROR: No VoteChange found for project #{id} at vote count #{target_vote_count}!"
        puts "Available vote counts for this project: #{VoteChange.where(project: self).pluck(:project_vote_count).sort}"
        # This should never happen!
        raise "ERROR: No VoteChange found for project #{id} at vote count #{target_vote_count}!"
      end

      pc = unlerp(min, max, current_rating)

      if pc < 0 || pc > 1
        raise "ERROR: Invalid percentile #{pc} for project #{id}. min=#{min}, max=#{max}, current_rating=#{current_rating}"
      end

      puts "FKDF", pc, min, max, current_rating

      mult = Payout.calculate_multiplier pc

      hours = ship.hours_covered

      amount = (mult * hours).ceil

      current_payout_sum = ship.payouts.sum(:amount)
      current_payout_difference = amount - current_payout_sum

      next if current_payout_difference.zero?

      reason = "Payout#{" recalculation" if ship.payouts.count > 0} for #{title}'s #{ship.created_at} ship."

      payout = Payout.create!(amount: current_payout_difference, payable: ship, user:, reason:, escrowed: false)

      puts "PAYOUTCREASED(#{payout.id}) ship.id:#{ship.id} min:#{min} max:#{max} rating_at_vote_count:#{current_rating} pc:#{pc} mult:#{mult} hours:#{hours} amount:#{amount} current_payout_sum:#{current_payout_sum} current_payout_difference:#{current_payout_difference}"
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

  def cannot_remove_locked_hackatime_keys
    return unless hackatime_project_keys_changed?

    original_keys = hackatime_project_keys_was || []
    new_keys = hackatime_project_keys || []
    removed_keys = original_keys - new_keys

    locked_keys = locked_hackatime_keys
    locked_removed_keys = removed_keys & locked_keys

    if locked_removed_keys.any?
      errors.add(:hackatime_project_keys, "Cannot remove keys that have been used in devlogs: #{locked_removed_keys.join(', ')}")
    end
  end

  def cannot_assign_globally_locked_hackatime_keys
    return unless hackatime_project_keys.present?

    new_keys = hackatime_project_keys || []

    new_keys.each do |key|
      if self.class.hackatime_key_locked_globally?(key, user_id)
        original_keys = persisted? ? (hackatime_project_keys_was || []) : []
        next if original_keys.include?(key)

        errors.add(:hackatime_project_keys, "Key '#{key}' is already being used by another project and cannot be assigned")
      end
    end
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
