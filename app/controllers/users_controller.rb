# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_api_key, only: [ :check_user ]
  before_action :authenticate_user!,
                only: %i[hackatime_auth_redirect identity_vault_callback]
  before_action :preload_current_user_associations, only: [ :show ]
  before_action :set_user, only: [ :show ]

  def show
    authorize @user
    if @user.is_banned?
      redirect_to root_path, alert: "This user has been banned." and return
    end
    @user.user_profile ||= @user.build_user_profile

    # All projects for the sidebar - use preloaded data and sort in memory
    @all_projects = @user.projects.sort_by(&:created_at).reverse

    # Get all activities from cache
    @activities = get_cached_activities

    # Preload liked devlog IDs for the current user to avoid N+1 queries in like buttons
    if user_signed_in?
      devlog_ids = @activities.select { |a| a[:type] == :devlog }.map { |a| a[:item].id }
      @liked_devlog_ids = current_user.likes.where(likeable_type: "Devlog", likeable_id: devlog_ids).pluck(:likeable_id).to_set
    end

    # Precompute stats using preloaded data - no additional DB queries needed
    @stats = {
      projects_count: @user.projects.size,
      devlogs_count: @user.devlogs.size,
      votes_count: @user.votes.count { |v| v.status == "active" },  # Use preloaded data with scope logic
      ships_count: @user.projects.count { |p| p.ship_events.any? }
    }

    # Precompute project metrics to avoid N+1 in views
    @project_devlog_counts = {}
    @project_follower_counts = {}
    @project_shipped_status = {}

    @user.projects.each do |project|
      @project_devlog_counts[project.id] = project.devlogs.size
      @project_follower_counts[project.id] = project.followers.size
      @project_shipped_status[project.id] = project.ship_events.any?
    end

    # Precompute badges to avoid N+1 queries in the view
    @user_badges = @user.badges


    respond_to do |format|
      format.html
    end
  end



  def check_user
    user = User.find_by(slack_id: params[:slack_id])

    if user&.projects&.any?
      render json: { exists: true, has_project: true, projects: user.projects }, status: :ok
    elsif user
      render json: { exists: true, has_project: false }, status: :ok
    else
      render json: { exists: false, has_project: false }, status: :not_found
    end
  end

  def identity_vault_callback
    begin
      current_user.link_identity_vault_callback(identity_vault_callback_url, params[:code])
      begin
        current_user.sync_slack_id_into_idv!
      rescue => e
        Honeybadger.notify(e)
      end
      ahoy.track "tutorial_step_identity_vault_linked", user_id: current_user.id
    rescue StandardError => e
      uuid = Honeybadger.notify(e)
      return redirect_to shop_path, alert: "Couldn't link identity: #{e.message} (ask support about error ID #{uuid}?)"
    end
    redirect_to order_shop_item_path(ShopItem::FreeStickers.first), notice: "Successfully linked your identity!"
  end

  def link_identity_vault
    return redirect_to root_path unless current_verification_status == :not_linked

    ahoy.track "tutorial_step_identity_vault_redirect", user_id: current_user.id

    redirect_to current_user.identity_vault_oauth_link(identity_vault_callback_url), allow_other_host: true
  end

  def hackatime_auth_redirect
    if current_user.has_hackatime?
      redirect_to root_path, notice: "You're already connected to Hackatime!"
      return
    end

    ahoy.track "tutorial_step_hackatime_redirect", user_id: current_user.id

    bypass_keys = ENV.fetch("HACKATIME_BYPASS_KEYS", "").split(",")
    response = nil
    res = nil

    begin
      bypass_keys.each do |bypass_key|
        response = Faraday.new do |f|
          f.request :url_encoded
          f.response :json, parser_options: { symbolize_names: true, rescue_parse_errors: true }
          f.headers["Authorization"] = "Bearer #{Rails.application.credentials.dig(:hackatime, :internal_key)}"
          f.headers["Rack-Attack-Bypass"] = bypass_key
        end
        .post(
          "https://hackatime.hackclub.com/api/internal/can_i_have_a_magic_link_for/#{current_user.slack_id}",
          {
            email: current_user.email,
            return_data: {
              url: campfire_url,
              button_text: "head back to Summer of Making!"
            }
          }
        )
        res = response.body
        break unless response.status == 429
      end
      pp "HACKATIMEAUTHREDIRECTRESULT", res

      if response.status == 429
        Rails.logger.error("hackatime rate limited: status=429, body=#{res.inspect}")
        Honeybadger.notify("hackatime rate limited: status=429, body=#{res.inspect}")
        reset_at = res.is_a?(Hash) ? res[:reset_at] : nil
        msg = "HackaTime is getting dizzy from all the traffic, give it a moment to catch its breath!"
        msg += " (Try again after #{reset_at})" if reset_at
        redirect_to root_path, alert: msg
        return
      end

      if response.status != 200
        if res.is_a?(String) && res.strip.start_with?("<!doctype html")
          Rails.logger.error("hackatime api returned HTML error page: status=#{response.status}, body=#{res[0..300]}...")
          Honeybadger.notify("hackatime api returned HTML error page: status=#{response.status}, body=#{res[0..300]}...")
          redirect_to root_path, alert: "Hackatime returned a really weird error, give it another go?"
          return
        end
        Rails.logger.error("hackatime api fucky wucky status=#{response.status}, body=#{res.inspect}")
        Honeybadger.notify("hackatime api fucky wucky: status=#{response.status}, body=#{res.inspect}")
        redirect_to root_path, alert: "Failed to connect to HackaTime (API error). Please try again later or contact support."
        return
      end

      magic_link = res.is_a?(Hash) ? res[:magic_link] : nil
      if magic_link.blank?
        Rails.logger.error("hackatime never provided magic_link: #{res.inspect}")
        Honeybadger.notify("hackatime never provided magic_link: #{res.inspect}")
        redirect_to root_path, alert: "Hackatime did not return the data we expected, give it another go?"
        return
      end

      redirect_to magic_link, allow_other_host: true
    rescue Faraday::Error => e
      Rails.logger.error("hackatime connection error: #{e.class} #{e.message}")
      Honeybadger.notify(e)
      redirect_to root_path, alert: "Could not connect to Hackatime, give it another go?"
    rescue => e
      Rails.logger.error("random ass error: #{e.class} #{e.message}")
      Honeybadger.notify(e)
      redirect_to root_path, alert: "An unexpected error occurred while connecting to Hackatime. Give it another go?"
    end
  end

  private

  def get_cached_activities
    # Create cache key based on user and their content timestamps
    # Use preloaded data for timestamp calculations to avoid DB hits
    projects_max = @user.projects.map(&:updated_at).max
    devlogs_max = @user.devlogs.map(&:updated_at).max
    cache_key = "user_activities_#{@user.id}_#{@user.updated_at.to_i}_#{projects_max&.to_i}_#{devlogs_max&.to_i}"

    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      # Use preloaded data instead of making new DB queries
      devlogs = @user.devlogs.select { |d| d.project.present? }
                             .sort_by(&:created_at).reverse

      projects = @user.projects.sort_by(&:created_at).reverse

      # Combine and sort chronologically
      combined_activities = []

      # Add devlogs with type marker (including orphaned ones)
      devlogs.each { |devlog| combined_activities << { type: :devlog, item: devlog, created_at: devlog.created_at } }

      # Add projects with type marker
      projects.each { |project| combined_activities << { type: :project, item: project, created_at: project.created_at } }

      # Add shipwright advice for this user's projects
      advices = ShipwrightAdvice.includes(
        :project,
        ship_certification: [ :reviewer ]
      ).joins(:project)
       .where(projects: { user: @user })
       .order(created_at: :desc)

      advices.each { |advice| combined_activities << { type: :shipwright_advice, item: advice, created_at: advice.created_at } }

      # Add user joined activity
      combined_activities << { type: :user_joined, item: @user, created_at: @user.created_at }

      # Sort by created_at descending (newest first)
      combined_activities.sort! { |a, b| b[:created_at] <=> a[:created_at] }

      combined_activities
    end
  end

  def authenticate_api_key
    api_key = request.headers["Authorization"]
    return if api_key.present? && api_key == ENV["API_KEY"]

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def set_user
    @user = if params[:id] == "me"
      # For current user, ensure user_badges is loaded
      current_user.tap { |user| user.user_badges.load unless user.association(:user_badges).loaded? }
    else
      # Preload associations needed for the view and cached activities
      scope = User.preload(
        :user_profile,    # Used for bio, custom CSS checks
        :user_badges,     # Used for @user_badges and has_badge? checks
        :payouts,         # Used for balance calculations
        :user_hackatime_data,  # Used for has_hackatime? and coding time stats
        { votes: [] },    # Used for vote count stats
        { devlogs: [      # Used in activities feed - need project and user for devlog cards
          :project,       # devlog.project.present? check and devlog card project info
          { user: [ :user_badges ] },  # devlog.user.avatar, display_name, and badge checks
          file_attachment: [ :blob ] # devlog.file.attached? and file rendering
        ] },
        { projects: [     # Used in @all_projects sidebar and activities
          :devlogs,       # For devlog count in sidebar
          :ship_events,   # For "Shipped" status and ships count
          :followers,     # For follower count in sidebar
          { user: [ :user_badges ] },  # project.user.avatar, display_name, and badge checks
          banner_attachment: [ :blob ]  # For project thumbnails
        ] }
      )
      scope = scope.where(user_profiles: { hide_from_logged_out: [ false, nil ] }) unless user_signed_in?
      scope.find(params[:id])
    end
  end
end
