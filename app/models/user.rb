# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                                   :bigint           not null, primary key
#  avatar                               :string
#  display_name                         :string
#  email                                :string
#  first_name                           :string
#  freeze_shop_activity                 :boolean          default(FALSE)
#  has_black_market                     :boolean
#  has_clicked_completed_tutorial_modal :boolean          default(FALSE), not null
#  has_commented                        :boolean          default(FALSE)
#  has_hackatime                        :boolean          default(FALSE)
#  has_hackatime_account                :boolean
#  identity_vault_access_token          :string
#  internal_notes                       :text
#  is_admin                             :boolean          default(FALSE), not null
#  is_banned                            :boolean          default(FALSE)
#  fraud_team_member                    :boolean          default(FALSE), not null
#  last_name                            :string
#  permissions                          :text             default([])
#  shenanigans_state                    :jsonb
#  synced_at                            :datetime
#  timezone                             :string
#  tutorial_video_seen                  :boolean          default(FALSE), not null
#  ysws_verified                        :boolean          default(FALSE)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  identity_vault_id                    :string
#  slack_id                             :string
#
class User < ApplicationRecord
  has_paper_trail

  has_many :projects
  has_many :devlogs
  has_many :votes
  has_one :user_vote_queue, dependent: :destroy
  has_many :project_follows
  has_many :followed_projects, through: :project_follows, source: :project
  has_many :timer_sessions
  has_many :stonks
  has_many :staked_projects, through: :stonks, source: :project
  has_many :ship_events, through: :projects
  has_many :payouts
  has_one :user_hackatime_data, dependent: :destroy
  has_one :user_profile, class_name: "User::Profile", dependent: :destroy
  has_one :tutorial_progress, dependent: :destroy
  has_one :magic_link, dependent: :destroy
  has_many :shop_orders
  has_many :shop_card_grants
  has_many :user_badges, dependent: :destroy

  accepts_nested_attributes_for :user_profile
  has_many :hackatime_projects
  has_many :fraud_reports, foreign_key: :user_id, class_name: "FraudReport", dependent: :destroy

  before_validation { self.email = email.to_s.downcase.strip }

  validates :slack_id, presence: true, uniqueness: true
  validates :email, :display_name, :timezone, :avatar, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :display_name, presence: true, length: { maximum: 100 }
  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true

  serialize :permissions, type: Array, coder: JSON

  after_create :create_tutorial_progress
  after_find :setup_mock_verified_user, if: -> { should_mock_verification }
  after_initialize :setup_mock_verified_user, if: -> { should_mock_verification }

  include PublicActivity::Model
  tracked only: [], owner: Proc.new { |controller, model| controller&.current_user }

  scope :search, ->(query) {
    return all if query.blank?

    query = "%#{query}%"
    where(
      "first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR slack_id ILIKE ? OR display_name ILIKE ? OR identity_vault_id ILIKE ?",
      query, query, query, query, query, query
    )
  }

  def self.exchange_slack_token(code, redirect_uri)
    response = Faraday.post("https://slack.com/api/oauth.v2.access",
                            {
                              client_id: ENV.fetch("SLACK_CLIENT_ID", nil),
                              client_secret: ENV.fetch("SLACK_CLIENT_SECRET", nil),
                              redirect_uri: redirect_uri,
                              code: code
                            })

    result = JSON.parse(response.body)

    unless result["ok"]
      Rails.logger.error("Slack OAuth error: #{result['error']}")
      Honeybadger.notify("Slack OAuth error: #{result['error']}")
      raise StandardError, "Failed to authenticate with Slack: #{result['error']}"
    end

    slack_id = result["authed_user"]["id"]
    user = User.find_by(slack_id: slack_id)
    if user.present?
      Rails.logger.tagged("UserCreation") do
        Rails.logger.info({
          event: "existing_user_found",
          slack_id: slack_id,
          user_id: user.id,
          email: user.email
        }.to_json)
      end

      user.refresh_profile!

      return user
    end

    user = create_from_slack(slack_id)
    check_hackatime(slack_id)
    user
  end

  def self.create_from_slack(slack_id)
    user_info = fetch_slack_user_info(slack_id)
    if user_info.user.is_bot
      Rails.logger.warn({
        event: "slack_user_is_bot",
        slack_id: slack_id,
        user_info: user_info.to_h
      }.to_json)
      return nil
    end

    email = user_info.user.profile.email
    display_name = user_info.user.profile.display_name.presence || user_info.user.profile.real_name
    timezone = user_info.user.tz
    avatar = user_info.user.profile.image_192 || user_info.user.profile.image_512

    Rails.logger.tagged("UserCreation") do
      Rails.logger.info({
        event: "slack_user_found",
        slack_id: slack_id,
        email: email,
        display_name: display_name,
        timezone: timezone,
        avatar: avatar
      }.to_json)
    end

    if email.blank? || !(email =~ URI::MailTo::EMAIL_REGEXP)
      Rails.logger.warn({
        event: "slack_user_missing_or_invalid_email",
        slack_id: slack_id,
        email: email,
        user_info: user_info.to_h
      }.to_json)
      Honeybadger.notify("slack email fuck up???", context: {
        slack_id: slack_id,
        email: email,
        user_info: user_info.to_h
      })
      raise StandardError, "slack #{slack_id} has a fuck ass email? #{email.inspect}"
    end

    User.create!(
      slack_id: slack_id,
      display_name: display_name,
      email: email,
      timezone: timezone,
      avatar: avatar,
      permissions: [],
      is_banned: false
    )
  end

  def self.check_hackatime(slack_id)
    user = User.find_by(slack_id:)

    response = user.fetch_raw_hackatime_stats
    result = JSON.parse(response.body)&.dig("data")

    return unless result["status"] == "ok"

    user.has_hackatime = true
    user.save!

    stats = user.user_hackatime_data || user.build_user_hackatime_data
    stats.update(data: result, last_updated_at: Time.current)
  end

  def self.fetch_slack_user_info(slack_id)
    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))
    r = 0
    begin
      client.users_info(user: slack_id)
    rescue Slack::Web::Api::Errors::TooManyRequestsError => e
      if r < 3
        s = e.retry_after
        Rails.logger.warn("slack api ratelimit, retry in #{s} count#{r + 1}")
        sleep s
        r += 1
        retry
      else
        Rails.logger.error("slack api ratelimit, max retries on #{slack_id}.")
        Honeybadger.notify("slack api ratelimit, max retries on #{slack_id}.")
        raise
      end
    end
  end

  def refresh_profile!
    Rails.logger.tagged("ProfileRefresh") do
      Rails.logger.info({
        event: "refreshing_profile_data",
        user_id: id,
        slack_id: slack_id
      }.to_json)
    end

    user_info = User.fetch_slack_user_info(slack_id)

    new_display_name = user_info.user.profile.display_name.presence || user_info.user.profile.real_name
    new_email = user_info.user.profile.email
    new_timezone = user_info.user.tz
    new_avatar = user_info.user.profile.image_original.presence || user_info.user.profile.image_512

    changes = {}
    changes[:display_name] = { from: display_name, to: new_display_name } if display_name != new_display_name
    changes[:email] = { from: email, to: new_email } if email != new_email
    changes[:timezone] = { from: timezone, to: new_timezone } if timezone != new_timezone
    changes[:avatar] = { from: avatar, to: new_avatar } if avatar != new_avatar

    if changes.any?
      Rails.logger.tagged("ProfileRefresh") do
        Rails.logger.info({
          event: "profile_changes_detected",
          user_id: id,
          slack_id: slack_id,
          changes: changes
        }.to_json)
      end

      update!(
        display_name: new_display_name,
        email: new_email,
        timezone: new_timezone,
        avatar: new_avatar
      )

      Rails.logger.tagged("ProfileRefresh") do
        Rails.logger.info({
          event: "profile_refresh_success",
          user_id: id,
          slack_id: slack_id
        }.to_json)
      end
    else
      Rails.logger.tagged("ProfileRefresh") do
        Rails.logger.debug({
          event: "profile_refresh_no_change",
          user_id: id,
          slack_id: slack_id
        }.to_json)
      end
    end
  rescue StandardError => e
    Rails.logger.tagged("ProfileRefresh") do
      Rails.logger.error({
        event: "profile_refresh_failed",
        user_id: id,
        slack_id: slack_id,
        error: e.message
      }.to_json)
    end

    Honeybadger.notify(e, context: { user_id: id, slack_id: slack_id })
  end

  def hackatime_projects
    user_hackatime_data&.projects || []
  end

  def format_seconds(seconds)
    return "0h 0m" if seconds.nil? || seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    "#{hours}h #{minutes}m"
  end
  # all time
  def all_time_coding_seconds
    user_hackatime_data&.projects&.sum { |p| p[:total_seconds] } || 0
  end

  # 24 hrs
  def daily_coding_seconds
    return 0 unless has_hackatime?

    # get user's tz
    user_timezone = timezone.present? ? timezone : "UTC"
    today_start = Time.use_zone(user_timezone) { Time.current.beginning_of_day }

    response = fetch_raw_hackatime_stats(from: today_start)
    return 0 unless response&.success?

    result = JSON.parse(response.body)
    return 0 unless result&.dig("data", "status") == "ok"

    result.dig("data", "total_seconds")
  rescue => e
    Rails.logger.error("Failed to fetch today's hackatime data: #{e.message}")
    0
  end

  # This is a network call. Do you really need to use this?
  def fetch_raw_hackatime_stats(from: nil, to: nil)
    Rails.cache.fetch("User.fetch_raw_hackatime_stats/#{id}/#{from}-#{to}/1", expires_in: 5.seconds) do
      if from.present?
        start_date = Time.parse(from.to_s).utc.freeze
      else
        start_date = begin
          Time.use_zone("America/New_York") do
            Time.parse("2025-06-16").beginning_of_day
          end
        end.utc.freeze
      end

      if to.present?
        end_date = Time.parse(to.to_s).utc.freeze
      end

      url = "https://hackatime.hackclub.com/api/v1/users/#{slack_id}/stats?features=projects&start_date=#{start_date}&test_param=true"
      url += "&end_date=#{end_date}" if end_date.present?

      Faraday.get(url, nil, { "RACK_ATTACK_BYPASS" => ENV["HACKATIME_BYPASS_KEYS"] }.compact)
    end
  end

  def refresh_hackatime_data_now
    response = fetch_raw_hackatime_stats
    return unless response.success?

    result = JSON.parse(response.body)
    projects = result.dig("data", "projects")
    has_hackatime_account = result.dig("data", "status") == "ok"

    trust_value = result.dig("trust_factor", "trust_value")
    should_ban = trust_value == 1

    if should_ban && !is_banned
      ban_user!("hackatime_ban")
    elsif !should_ban && is_banned
      unban_user!
    end

    if projects.empty?
      update!(has_hackatime_account:)
      return
    end

    update!(has_hackatime_account:, has_hackatime: true)

    Rails.logger.tagged("User.refresh_hackatime_data_now") do
      Rails.logger.debug("User #{id} (#{slack_id}) total seconds: #{result.dig("data", "total_seconds")}")
    end

    rows = projects
      .map { |p| { user_id: id, name: p["name"], seconds: p["total_seconds"] } }
      .reject { |p| [ "<<LAST_PROJECT>>", "Other" ].include?(p[:name]) }
      .group_by { |r| r[:name] }
      .map { |name, group| group.reduce { |acc, h| acc.merge(seconds: acc[:seconds] + h[:seconds]) } }

    HackatimeProject.upsert_all(
      rows,
      unique_by: %i[user_id name],
      update_only: %i[seconds],
      record_timestamps: true
    )

    stats = user_hackatime_data || build_user_hackatime_data
    stats.update(data: result, last_updated_at: Time.current)
  end

  def has_hackatime?
    has_hackatime
  end

  def can_stake_more_projects?
    staked_projects.distinct.count < 5
  end

  def staked_projects_count
    staked_projects.distinct.count
  end

  def give_black_market!
    update!(has_black_market: true)
    SendSlackDmJob.perform_later slack_id, <<~EOM
      Psst... hey, kid... Booth’s been watchin’. Says you’re one of the real ones. You build like it means something, not like these others out here playin’ pretend. You build for yourself, for your crew, maybe even for the whole damn world. You get the hustle. You live it.
      So here’s the deal... he wants you in. On the real goodies. Remember the normal shop? Forget it. That was just the lobby. We got what you’re really lookin’ for now. Welcome to <https://summer.hackclub.com/shop/black_market|heidimarket>.
      Keep it buried. Eyes low, lips sealed. Last thing we need is the whole block sniffin’ around where they don’t belong.
    EOM
  end

  # we can add more cooler stuff, and more fine grained access controls for other parts later
  def has_permission?(permission)
    return false if permissions.nil? || permissions.empty?
    permissions.include?(permission.to_s)
  end

  def add_permission(permission)
    current_permissions = permissions || []
    current_permissions << permission.to_s unless current_permissions.include?(permission.to_s)
    update!(permissions: current_permissions)
  end

  def remove_permission(permission)
    current_permissions = permissions || []
    current_permissions.delete(permission.to_s)
    update!(permissions: current_permissions)
  end

  def ship_certifier?
    has_permission?("shipcert")
  end

  def admin_or_ship_certifier?
    is_admin? || ship_certifier?
  end

  def blue_check?
    has_badge?(:verified)
  end

  def gold_check?
    has_badge?(:gold_verified)
  end

  def verified_check?
    blue_check? || gold_check?
  end

  def neon_flair?
    !!shenanigans_state["neon_flair"]
  end

  def projects_left_to_stake
    5 - staked_projects_count
  end

  def ensure_permissions_initialized
    if permissions.nil?
      self.permissions = []
    end
  end

  def balance
    if association(:payouts).loaded?
      payouts.sum(&:amount)
    else
      payouts.sum(:amount)
    end
  end

  def ship_events_count
    projects.joins(:ship_events)
            .left_joins(ship_events: :payouts)
            .distinct
            .size
  end

  # Avo backtraces
  def is_developer?
    slack_id == "U03DFNYGPCN"
  end

  def fraud_team_member?
    fraud_team_member
  end

  def identity_vault_oauth_link(callback_url)
    IdentityVaultService.authorize_url(callback_url, {
                                         prefill: {
                                           email: email,
                                           first_name: first_name,
                                           last_name: last_name
                                         },
                                         context: "stickers",
                                         invalidate_session: true
                                       })
  end

  def fetch_idv(access_token = nil)
    IdentityVaultService.me(access_token || identity_vault_access_token)
  end

  def link_identity_vault_callback(callback_url, code)
    code_response = IdentityVaultService.exchange_token(callback_url, code)

    access_token = code_response[:access_token]

    idv_data = fetch_idv(access_token)
    identity_vault_id = idv_data.dig(:identity, :id)

    # Ensure no other user has this identity_vault_id linked already
    if User.where.not(id:).exists?(identity_vault_id:)
      raise StandardError, "Another user already has this identity linked."
    end

    update!(
      identity_vault_access_token: access_token,
      identity_vault_id:,
      ysws_verified: idv_data.dig(:identity,
                                  :verification_status) == "verified" && idv_data.dig(:identity, :ysws_eligible)
    )
  end

  def refresh_identity_vault_data!
    idv_data = fetch_idv

    update!(
      first_name: idv_data.dig(:identity, :first_name),
      last_name: idv_data.dig(:identity, :last_name),
      ysws_verified: idv_data.dig(:identity,
                                  :verification_status) == "verified" && idv_data.dig(:identity, :ysws_eligible)
    )
  end

  def sync_slack_id_into_idv!
    IdentityVaultService.set_slack_id(identity_vault_id, slack_id)
  end

  def has_idv_addresses?
    return false if identity_vault_access_token.blank?

    begin
      idv_data = fetch_idv
      addresses = idv_data.dig(:identity, :addresses)
      addresses.present? && addresses.any?
    rescue => e
      Rails.logger.error "Failed to fetch IDV addresses: #{e.message}"
      false
    end
  end

  def verification_status
    return :not_linked if identity_vault_id.blank?

    # rapid identify theft
    if Rails.env.development? && ENV["BYPASS_IDV"] == "true"
      notify_xyz_on_verified
      update(ysws_verified: true) unless ysws_verified?
      return :verified
    end

    idv_data = fetch_idv[:identity]

    case idv_data[:verification_status]
    when "pending"
      :pending
    when "needs_submission"
      :needs_resubmission
    when "verified"
      if idv_data[:ysws_eligible]
        notify_xyz_on_verified
        update(ysws_verified: true) unless ysws_verified?
        :verified
      else
        :ineligible
      end
    else
      :ineligible
    end
  end

  def identity_vault_linked?
    identity_vault_access_token.present?
  end

  # DO NOT DO THIS
  def nuke_idv_data!
    update!(identity_vault_access_token: nil, identity_vault_id: nil)
  end

  def ban_user!(reason = "admin_ban")
    return if is_banned?
    update!(is_banned: true)
    projects.with_deleted.where(user_id: id).update_all(is_deleted: true)
    create_activity("ban_user", params: { reason: reason })
    Rails.logger.info("user #{id} (#{slack_id}) ratioed thanks to #{reason}")
  end

  def unban_user!
    return unless is_banned?
    update!(is_banned: false)
    create_activity("unban_user")
    Rails.logger.info("user #{id} (#{slack_id}) is back")
  end

  # Badge methods
  def badges
    Badge.earned_by(self)
  end

  def has_badge?(badge_key)
    # we're preload this in shop items controller
    if association(:user_badges).loaded?
      user_badges.any? { |ub| ub.badge_key.to_s == badge_key.to_s }
    else
      user_badges.exists?(badge_key: badge_key)
    end
  end

  def award_badges!(backfill: false)
    Badge.award_badges_for(self, backfill: backfill)
  end

  def award_badges_async!(trigger_event = nil, backfill: false)
    AwardBadgesJob.perform_later(id, trigger_event, backfill)
  end

  def advance_vote_queue!
    if user_vote_queue
      result = user_vote_queue.advance_position!
      result
    else
      false
    end
  end

  def completed_todo?
    devlogs.any? && projects.any? && votes.any? && shop_orders.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" }).any?
  end

  private

  def should_mock_verification
    Rails.env.development? && ENV["MOCK_VERIFIED_USER"] == "true"
  end

  def create_tutorial_progress
    TutorialProgress.create!(user: self)
  end

  def setup_mock_verified_user
    return unless should_mock_verification

    assign_attributes(
      identity_vault_id: "mock_#{SecureRandom.hex(8)}",
      identity_vault_access_token: "mock_#{SecureRandom.hex(16)}",
      ysws_verified: true
    )
  end

  def permissions_must_not_be_nil
    if permissions.nil?
      ensure_permissions_initialized
    end
  end

  def notify_xyz_on_verified
      # if  ysws_verified
      begin
        uri = URI.parse("https://explorpheus.hackclub.com/verified")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = JSON.generate({
          token: Rails.application.credentials.explorpheus.token,
          slack_id: slack_id,
          email: email
        })

        # Send the request
        response = http.request(request)
        response
      rescue => e
        Rails.logger.error("Failed to notify xyz.hackclub.com: #{e.message}")
      end
    # end
  end
end
