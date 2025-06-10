# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
#  avatar                       :string
#  display_name                 :string
#  email                        :string
#  first_name                   :string
#  hackatime_confirmation_shown :boolean          default(FALSE)
#  has_black_market             :boolean
#  has_commented                :boolean          default(FALSE)
#  has_hackatime                :boolean          default(FALSE)
#  identity_vault_access_token  :string
#  internal_notes               :text
#  is_admin                     :boolean          default(FALSE), not null
#  last_name                    :string
#  timezone                     :string
#  ysws_verified                :boolean          default(FALSE)
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  identity_vault_id            :string
#  slack_id                     :string
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

  validates :slack_id, presence: true, uniqueness: true
  validates :email, :display_name, :timezone, :avatar, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_tutorial_progress
  after_commit :sync_to_airtable, on: %i[create update]

  include PublicActivity::Model
  tracked only: [], owner: Proc.new { |controller, model| controller&.current_user }

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
    # eligible_record = check_eligibility(slack_id)

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
      avatar: user_info.user.profile.image_original.presence || user_info.user.profile.image_512
    )
  end

  def self.check_hackatime(slack_id)
    response = Faraday.get("https://hackatime.hackclub.com/api/v1/users/#{slack_id}/stats?features=projects")
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
    return [] unless has_hackatime?

    projects = hackatime_stat&.data&.dig("data", "projects") || []

    projects.map do |project|
      {
        key: project["name"],
        name: project["name"],
        total_seconds: project["total_seconds"],
        formatted_time: project["text"]
      }
    end.sort_by { |p| p[:name] }
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

  def refresh_hackatime_data_now
    response = Faraday.get("https://hackatime.hackclub.com/api/v1/users/#{slack_id}/stats?features=projects")
    return unless response.success?

    result = JSON.parse(response.body)
    return unless result.dig("data", "status") == "ok"

    unless has_hackatime?
      update!(has_hackatime: true)
    end

    stats = hackatime_stat || build_hackatime_stat
    stats.update(data: result, last_updated_at: Time.current)
  end

  def project_time_from_hackatime(project_key)
    data = hackatime_stat&.data
    project_stats = data["projects"]&.find { |p| p["key"] == project_key }
    project_stats&.dig("total") || 0
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
                                         }
                                       })
  end

  def fetch_idv(access_token = nil)
    IdentityVaultService.me(access_token || identity_vault_access_token)
  end

  def link_identity_vault_callback(callback_url, code)
    code_response = IdentityVaultService.exchange_token(callback_url, code)

    access_token = code_response[:access_token]

    idv_data = fetch_idv(access_token)

    update!(
      identity_vault_access_token: access_token,
      identity_vault_id: idv_data.dig(:identity, :id),
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
        :verified
      else
        :ineligible
      end
    else
      :ineligible
    end
  end

  private

  def sync_to_airtable
    SyncUserToAirtableJob.perform_later(id)
  end

  def create_tutorial_progress
    TutorialProgress.create!(user: self)
  end
end
