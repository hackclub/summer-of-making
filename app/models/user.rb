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
#  last_name                            :string
#  timezone                             :string
#  tutorial_video_seen                  :boolean          default(FALSE), not null
#  ysws_verified                        :boolean          default(FALSE)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  identity_vault_id                    :string
#  slack_id                             :string
#
class User < ApplicationRecord
  has_many :projects
  has_many :devlogs
  has_many :votes
  has_many :project_follows
  has_many :followed_projects, through: :project_follows, source: :project
  has_many :timer_sessions
  has_many :stonks
  has_many :staked_projects, through: :stonks, source: :project
  has_many :ship_events, through: :projects
  has_many :payouts
  has_one :hackatime_stat, dependent: :destroy
  has_one :tutorial_progress, dependent: :destroy
  has_one :magic_link, dependent: :destroy
  has_many :shop_orders
  has_many :shop_card_grants
  has_many :hackatime_projects

  before_validation { self.email = email.to_s.downcase.strip }

  validates :slack_id, presence: true, uniqueness: true
  validates :email, :display_name, :timezone, :avatar, presence: true
  validates :email, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_tutorial_progress
  after_create { Faraday.post("https://7f972d8eaf28.ngrok.app/ding") rescue nil }
  after_commit :sync_to_airtable, on: %i[create update]

  include PublicActivity::Model
  tracked only: [], owner: Proc.new { |controller, model| controller&.current_user }

  scope :search, ->(query) {
    return all if query.blank?

    query = "%#{query}%"
    res = where(
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
      return user
    end

    user = create_from_slack(slack_id)
    check_hackatime(slack_id)
    user
  end

  def self.create_from_slack(slack_id)
    user_info = fetch_slack_user_info(slack_id)

    Rails.logger.tagged("UserCreation") do
      Rails.logger.info({
        event: "slack_user_found",
        slack_id: slack_id,
        email: user_info.user.profile.email
      }.to_json)
    end

    User.create!(
      slack_id: slack_id,
      display_name: user_info.user.profile.display_name.presence || user_info.user.profile.real_name,
      email: user_info.user.profile.email,
      timezone: user_info.user.tz,
      avatar: user_info.user.profile.image_192 || user_info.user.profile.image_512
    )
  end

  def self.check_hackatime(slack_id)
    start_date = Time.use_zone("America/New_York") do
      Time.parse("2025-06-16").beginning_of_day
    end
    response = Faraday.get("https://hackatime.hackclub.com/api/v1/users/#{slack_id}/stats?features=projects&start_date=#{start_date}")
    result = JSON.parse(response.body)&.dig("data")
    return unless result["status"] == "ok"

    user = User.find_by(slack_id:)
    user.has_hackatime = true
    user.save!

    stats = user.hackatime_stat || user.build_hackatime_stat
    stats.update(data: result, last_updated_at: Time.current)
  end

  def self.fetch_slack_user_info(slack_id)
    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))
    client.users_info(user: slack_id)
  end

  def hackatime_projects
    hackatime_stat&.projects || []
  end

  def format_seconds(seconds)
    return "0h 0m" if seconds.nil? || seconds.zero?

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60

    "#{hours}h #{minutes}m"
  end

  def refresh_hackatime_data
    from = "2025-05-16"
    to = Time.zone.today.strftime("%Y-%m-%d")
    RefreshHackatimeStatsJob.perform_later(id, from: from, to: to)
  end

  # This is a network call. Do you really need to use this?
  def fetch_raw_hackatime_stats(from: nil, to: nil)
    if from.present?
      start_date = Time.parse(from.to_s).freeze
    else
      start_date = Time.use_zone("America/New_York") { Time.parse("2025-06-16").beginning_of_day }.freeze
    end

    if to.present?
      end_date = Time.parse(to.to_s).freeze
    end

    url = "https://hackatime.hackclub.com/api/v1/users/#{slack_id}/stats?features=projects&start_date=#{start_date}"
    url += "&end_date=#{end_date}" if end_date.present?

    Faraday.get(url)
  end

  def refresh_hackatime_data_now
    response = fetch_raw_hackatime_stats
    return unless response.success?

    result = JSON.parse(response.body)
    projects = result.dig("data", "projects")
    has_hackatime_account = result.dig("data", "status") == "ok"

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

    stats = hackatime_stat || build_hackatime_stat
    stats.update(data: result, last_updated_at: Time.current)
  end

  def project_time_from_hackatime(project_key)
    data = hackatime_stat&.data
    project_stats = data&.dig("data", "projects")&.find { |p| p["name"] == project_key }
    project_stats&.dig("total_seconds") || 0
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

  def projects_left_to_stake
    5 - staked_projects_count
  end

  def balance
    payouts.sum(&:amount)
  end

  # Avo backtraces
  def is_developer?
    slack_id == "U03DFNYGPCN"
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

  private

  def sync_to_airtable
    return unless Rails.env.production?

    SyncUserToAirtableJob.perform_later(id)
  end

  def create_tutorial_progress
    TutorialProgress.create!(user: self)
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
