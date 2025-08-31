# frozen_string_literal: true

class ProjectsController < ApplicationController
  include ActionView::RecordIdentifier
  include ViewTrackable
  skip_before_action :verify_authenticity_token, only: [ :check_link ]
  before_action :set_project,
                only: %i[show edit update follow unfollow ship stake_stonks unstake_stonks destroy update_coordinates unplace_coordinates request_recertification]
  before_action :check_if_shipped, only: %i[edit update]
  before_action :authorize_user, only: [ :destroy ]
  before_action :require_hackatime, only: [ :create ]
  before_action :check_identity_verification, except: %i[show]
  skip_before_action :authenticate_user!, only: %i[show]

  def index
    sort_order = params[:sort] == "oldest" ? :asc : :desc
    if params[:tab] == "gallery"
      # Optimize gallery with pagination and DB-level ordering
      projects_query = Project.includes(:user, devlogs: [ :file_attachment ])
                              .joins("LEFT JOIN devlogs ON devlogs.project_id = projects.id")
                              .where(is_deleted: false)
                              .group("projects.id")
                              .order(Arel.sql("COUNT(devlogs.id) DESC, projects.created_at #{sort_order == :asc ? 'ASC' : 'DESC'}"))

      begin
        @pagy, @projects = pagy(projects_query, items: 12)
      rescue Pagy::OverflowError
        redirect_to projects_path(tab: "gallery", sort: params[:sort]) and return
      end
    elsif params[:tab] == "following"
      @followed_projects = current_user.followed_projects.includes(:user)
      @recent_devlogs = Devlog.joins(:project)
                              .joins("INNER JOIN project_follows ON project_follows.project_id = projects.id")
                              .includes(:project, :file_attachment, :user, comments: :user)
                              .where(project_follows: { user_id: current_user.id })
                              .where(projects: { is_deleted: false })
                              .order(created_at: :desc)

      begin
        @pagy, @recent_devlogs = pagy(@recent_devlogs, items: 8)
      rescue Pagy::OverflowError
        redirect_to projects_path(tab: "following") and return
      end
    elsif params[:tab] == "stonked"
      @stonked_projects = current_user.staked_projects.includes(:user)
      @recent_devlogs = Devlog.joins(:project)
                              .joins("INNER JOIN stonks ON stonks.project_id = projects.id")
                              .includes(:project, :file_attachment, :user, comments: :user)
                              .where(stonks: { user_id: current_user.id })
                              .where(projects: { is_deleted: false })
                              .order(created_at: :desc)

      begin
        @pagy, @recent_devlogs = pagy(@recent_devlogs, items: 8)
      rescue Pagy::OverflowError
        redirect_to projects_path(tab: "stonked") and return
      end
    else
      # Optimize main devlogs query
      devlogs_query = Devlog.joins(:project)
                            .includes(:project, :file_attachment, :user, comments: :user)
                            .where(projects: { is_deleted: false })
                            .order(created_at: :desc)

      begin
        @pagy, @recent_devlogs = pagy(devlogs_query, items: 8)
      rescue Pagy::OverflowError
        redirect_to projects_path and return
      end

      # we can just load stuff for the gallery here too!!
      projects_query = Project.includes(:banner_attachment, :user, devlogs: [ :file_attachment ])
                              .joins("LEFT JOIN devlogs ON devlogs.project_id = projects.id")
                              .where(is_deleted: false)
                              .group("projects.id")
                              .order(Arel.sql("COUNT(devlogs.id) DESC, projects.created_at #{sort_order == :asc ? 'ASC' : 'DESC'}"))

      begin
        @gallery_pagy, @projects = pagy(projects_query, items: 12)
      rescue Pagy::OverflowError
        @gallery_pagy, @projects = pagy(projects_query, items: 12, page: 1)
      end
    end
  end

  def show
    authorize @project, :show?
    track_view(@project)

    if current_user
      current_user.user_badges.load
      current_user.payouts.load
    end

    @devlogs = @project.devlogs.sort_by(&:created_at).reverse
    @ship_events = @project.ship_events.sort_by(&:created_at).reverse

    # Include shipwright advice in timeline for project owner only
    timeline_items = [ @devlogs, @ship_events ]
    if current_user == @project.user
      @shipwright_advices = @project.shipwright_advices.includes(:ship_certification).sort_by(&:created_at).reverse
      timeline_items << @shipwright_advices
    end

    @timeline = timeline_items.flatten.sort_by(&:created_at).reverse

    @stonks = @project.stonks.sort_by(&:amount).reverse
    @latest_ship_certification = @project.ship_certifications.max_by(&:created_at)

    @ship_event_data = compute_ship_event_data

    @project_image = pj_image

    # Handle devlog highlighting for direct devlog links
    @target_devlog_id = params[:devlog_id] if params[:devlog_id].present?

    # ID of newly created devlog for balloon animation
    @new_devlog_id = flash[:new_devlog_id] if flash[:new_devlog_id].present?

    return unless current_user

    if current_user == @project.user && current_user.has_hackatime?
      Rails.cache.fetch("hackatime_fetch_#{current_user.id}", expires_in: 30.seconds) do
        current_user.refresh_hackatime_data_now
      end
    end

    @user_stonk = @project.stonks.find { |stonk| stonk.user_id == current_user.id }

    # precoomputed liked state for devlogs
    if @devlogs.any?
      devlog_ids = @devlogs.map(&:id)
      @liked_devlog_ids = Like.where(user_id: current_user.id, likeable_type: "Devlog", likeable_id: devlog_ids)
                               .pluck(:likeable_id)
                               .to_set
    else
      @liked_devlog_ids = Set.new
    end
  end

  def edit
    return if current_user == @project.user

    redirect_to project_path(@project), alert: "You can only edit your own projects."
  end

  def create
    @project = current_user.projects.build(project_params)

    if not_img?(params[:project][:banner])
      flash.now[:alert] = "That is not a image!"
      render :index, status: :forbidden
      return
    end

    if @project.hackatime_project_keys.present?
      @project.hackatime_project_keys = @project.hackatime_project_keys.compact_blank.uniq
    end

    if @project.save
      is_first_project = current_user.projects.count == 1
      ahoy.track "tutorial_step_first_project_created", user_id: current_user.id, project_id: @project.id, is_first_project: is_first_project
      redirect_to project_path(@project), notice: "Project was successfully created."
    else
      flash.now[:alert] = "Could not create project. Please check the form for errors."
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if current_user == @project.user || current_user.is_admin?
      update_params = project_params

      if not_img?(update_params[:banner])
        flash.now[:alert] = "That is not a image!"
        render :edit, status: :forbidden
        return
      end

      if update_params[:hackatime_project_keys].present?
        update_params[:hackatime_project_keys] = update_params[:hackatime_project_keys].compact_blank.uniq
      end

      if @project.update(update_params)
        redirect_to project_path(@project), notice: "Project was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    else
      redirect_to project_path(@project), alert: "Something went wrong. Please try again."
    end
  end

  def my_projects
    @projects = current_user.projects.includes(
      :banner_attachment,
      { ship_events: :payouts },
      { devlogs: :file_attachment }
    ).order(created_at: :desc)
  end

  # Gotta say I love turbo frames and turbo streams and flashes in general
  def follow
    if current_user == @project.user
      respond_to do |format|
        format.html do
          redirect_to request.referer || projects_path, alert: "You cannot follow your own project"
        end
        format.turbo_stream do
          flash.now[:alert] = "You cannot follow your own project"
          render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash")
        end
      end
      return
    end

    @project_follow = current_user.project_follows.build(project: @project)

    respond_to do |format|
      if @project_follow.save
        message = "Well, would you look at that! 💅 You've got a brand new follower on your project: *#{@project.title}*! :ultrafastparrot:"
        SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?

        format.html do
          redirect_to request.referer || projects_path, notice: "You are now following this project!"
        end
        format.turbo_stream do
          flash.now[:notice] = "You are now following this project!"
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                 partial: "projects/follow_button",
                                 locals: { project: @project, following: true })
          ]
        end
      else
        error_message = @project_follow.errors.full_messages.join(", ")
        format.html do
          redirect_to request.referer || projects_path, alert: "Could not follow project: #{error_message}"
        end
        format.turbo_stream do
          flash.now[:alert] = "Could not follow project: #{error_message}"
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                 partial: "projects/follow_button",
                                 locals: { project: @project, following: false })
          ]
        end
      end
    end
  end

  def unfollow
    @project_follow = current_user.project_follows.find_by(project: @project)

    respond_to do |format|
      if @project_follow&.destroy
        format.html do
          redirect_to request.referer || projects_path, notice: "You have unfollowed this project."
        end
        format.turbo_stream do
          flash.now[:notice] = "You have unfollowed this project."
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                 partial: "projects/follow_button",
                                 locals: { project: @project, following: false })
          ]
        end
      else
        format.html { redirect_to request.referer || projects_path, alert: "Could not unfollow project." }
        format.turbo_stream do
          flash.now[:alert] = "Could not unfollow project."
          render turbo_stream: [
            turbo_stream.update("flash-container", partial: "shared/flash"),
            turbo_stream.replace(dom_id(@project, :follow_button),
                                 partial: "projects/follow_button",
                                 locals: { project: @project, following: true })
          ]
        end
      end
    end
  end

  def ship
    unless current_user == @project.user
      respond_to do |format|
        format.html { redirect_to project_path(@project), alert: "You can only ship your own project." }
        format.turbo_stream do
          flash.now[:alert] = "You can only ship your own project."
          render turbo_stream: turbo_stream.update("flash-container", partial: "shared/flash")
        end
      end
      return
    end

    # Verify all requirements are met
    errors = @project.shipping_errors

    if errors.any?
      redirect_to project_path(@project), alert: "Cannot ship project: #{errors.join(' ')}"
      return
    end

    if ShipEvent.create(project: @project, for_sinkening: Flipper.enabled?(:sinkening, current_user))
      if Flipper.enabled?(:sinkening, current_user)
        @project.update!(is_sinkening_ship: true)
      end

      is_first_ship = current_user.projects.joins(:ship_events).count == 1
      ahoy.track "tutorial_step_first_project_shipped", user_id: current_user.id, project_id: @project.id, is_first_ship: is_first_ship
      redirect_to project_path(@project), notice: "Your project has been shipped!"

      message = "Congratulations on shipping your project! Now thy project shall fight for blood :ultrafastparrot:"
      SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?
    else
      redirect_to project_path(@project), alert: "Could not ship project."
    end
  end

  def request_recertification
    unless current_user == @project.user
      redirect_to project_path(@project), alert: "You can only request re-certification for your own project."
      return
    end

    if @project.request_recertification!
      redirect_to project_path(@project), notice: "Re-certification requested! Your project will be reviewed again."
    else
      redirect_to project_path(@project), alert: "Cannot request re-certification for this project."
    end
  end

  # Some AI generated code to check if a link is a valid repo or readme link
  def check_link
    url = params[:url]&.strip&.gsub(/\A"|"\z/, "")
    link_type = params[:link_type]

    require "net/http"
    require "uri"

    begin
      uri = URI.parse(url)

      unless %w[http https].include?(uri.scheme&.downcase)
        render json: { valid: false, error: "That is not a proper link." }
        return
      end
      # Really, just trying to check if it's a valid repo or readme link and not some random link
      if %w[repo readme].include?(link_type)
        repo_patterns = [
          %r{/blob/}, %r{/tree/}, %r{/src/}, %r{/raw/}, %r{/commits/},
          %r{/pull/}, %r{/issues/}, %r{/compare/}, %r{/releases/},
          /\.git$/, %r{/commit/}, %r{/branch/}, %r{/blame/},

          %r{/projects/}, %r{/repositories/}, %r{/gitea/}, %r{/cgit/},
          %r{/gitweb/}, %r{/gogs/}, %r{/git/}, %r{/scm/},

          /\.(md|py|js|ts|jsx|tsx|html|css|scss|php|rb|go|rs|java|cpp|c|h|cs|swift)$/
        ]

        # Known code hosting platforms (not required, but used for heuristic)
        known_platforms = [
          "github", "gitlab", "bitbucket", "dev.azure", "sourceforge",
          "codeberg", "sr.ht", "replit", "vercel", "netlify", "glitch",
          "hackclub", "gitea", "git", "repo", "code"
        ]

        path = uri.path.downcase
        host = uri.host.downcase
        url.downcase

        is_valid_repo_url = false

        if repo_patterns.any? { |pattern| path.match?(pattern) }
          is_valid_repo_url = true
        elsif link_type == "readme" && (host.include?("raw.githubusercontent") || path.include?("/readme") || path.end_with?(".md") || path.end_with?("readme.txt"))
          is_valid_repo_url = true
        elsif known_platforms.any? { |platform| host.include?(platform) }
          is_valid_repo_url = path.split("/").size > 2
        elsif path.split("/").size > 1 && path.exclude?("wp-") && path.exclude?("blog")
          is_valid_repo_url = true
        end

        unless is_valid_repo_url
          error_message = if link_type == "repo"
                            "This doesn't appear to be a valid code repository URL. Please use a link to a repository structure."
          else
                            "This doesn't appear to be a valid documentation URL. Please use a link to a README file or documentation."
          end

          render json: { valid: false, error: error_message }
          return
        end
      end

      response = nil

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5,
                                          read_timeout: 10) do |http|
        request = Net::HTTP::Head.new(uri)
        request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        response = http.request(request)

        if response.code.to_i >= 300 && response.code.to_i < 400 && response["location"]
          redirect_uri = URI.parse(response["location"])
          redirect_uri = URI.join(uri.to_s, response["location"]) if redirect_uri.host.nil?

          redirect_request = Net::HTTP::Head.new(redirect_uri)
          redirect_request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"

          Net::HTTP.start(redirect_uri.host, redirect_uri.port, use_ssl: redirect_uri.scheme == "https",
                                                                open_timeout: 5, read_timeout: 10) do |redirect_http|
            response = redirect_http.request(redirect_request)
          end
        end
      end

      case response.code.to_i
      when 200..399
        render json: { valid: true }
      when 401, 403
        domain = uri.host
        auth_message = case domain
        when /github\.com/
                         "This GitHub repo appears to be private. Please make it public or choose a different repo."
        when /gitlab\.com/
                         "This GitLab repo appears to be private. Please make it public or choose a different repo."
        else
                         "This link requires authentication. Please make sure it's publicly accessible."
        end
        render json: { valid: false, error: auth_message }
      when 404
        render json: { valid: false, error: "URL not found (404). Please check the link." }
      when 429
        render json: { valid: false, error: "Rate limited by the server. Try again later." }
      when 500..599
        render json: { valid: false, error: "Server error (#{response.code}). The site might be down." }
      else
        render json: { valid: false, error: "Returned status code #{response.code}" }
      end
    rescue URI::InvalidURIError
      render json: { valid: false, error: "Invalid URL format. Please check the URL." }
    rescue Errno::ECONNREFUSED
      render json: { valid: false, error: "Connection refused. The server might be down." }
    rescue Net::OpenTimeout
      render json: { valid: false, error: "Connection timed out. The server might be slow or down." }
    rescue StandardError => e
      render json: { valid: false, error: e.message }
    end
  end

  def check_github_readme
    owner = params[:owner]
    repo = params[:repo]

    return render json: { error: "Missing owner or repo" }, status: :bad_request if owner.blank? || repo.blank?

    require "net/http"
    require "uri"

    begin
        # Check GitHub API for readme
        api_url = "https://api.github.com/repos/#{owner}/#{repo}/readme"
        uri = URI.parse(api_url)

        response = nil
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
            request = Net::HTTP::Get.new(uri)
            request["User-Agent"] = "HackClub-SummerOfMaking"
            request["Accept"] = "application/vnd.github.v3+json"
            response = http.request(request)
        end

        case response.code.to_i
        when 200
            readme_data = JSON.parse(response.body)
            readme_name = readme_data["name"]

            # Check if it's .md or .txt
            extension = File.extname(readme_name).downcase
            unless [ ".md", ".txt" ].include?(extension)
                return render json: { error: "README must be a .md or .txt file" }
            end

            # Construct the raw URL
            raw_url = "https://raw.githubusercontent.com/#{owner}/#{repo}/main/#{readme_name}"

            # Verify the raw URL exists
            raw_uri = URI.parse(raw_url)
            raw_response = nil
            Net::HTTP.start(raw_uri.host, raw_uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
                head_request = Net::HTTP::Head.new(raw_uri)
                head_request["User-Agent"] = "HackClub-SummerOfMaking"
                raw_response = http.request(head_request)
            end

            if raw_response.code.to_i == 200
                render json: { readme_url: raw_url }
            else
                # Try with master branch if main doesn't work
                master_url = "https://raw.githubusercontent.com/#{owner}/#{repo}/master/#{readme_name}"
                master_uri = URI.parse(master_url)

                Net::HTTP.start(master_uri.host, master_uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
                    head_request = Net::HTTP::Head.new(master_uri)
                    head_request["User-Agent"] = "HackClub-SummerOfMaking"
                    master_response = http.request(head_request)

                    if master_response.code.to_i == 200
                        render json: { readme_url: master_url }
                    else
                        render json: { error: "Could not access README file" }
                    end
                end
            end
        when 404
            render json: { error: "Repository or README not found" }
        when 403
            render json: { error: "Repository is private or rate limited" }
        else
            render json: { error: "GitHub API error: #{response.code}" }
        end
    rescue StandardError => e
        render json: { error: "Failed to check GitHub README: #{e.message}" }
    end
  end


  def stake_stonks
    @project = Project.find(params[:id])

    existing_stonk = current_user.stonks.find_by(project: @project)

    if existing_stonk.nil? && !current_user.can_stake_more_projects?
      redirect_to project_path(@project), alert: "You can only stake in a maximum of 5 projects"
      return
    end

    @stonk = Stonk.find_or_initialize_by(
      user: current_user,
      project: @project
    )

    @stonk.amount = Stonk::DEFAULT_AMOUNT

    if @stonk.save
      redirect_to project_path(@project), notice: "Successfully staked stonks!"

      message = "Wohoo! #{current_user.display_name} has staked stonks in your project: *#{@project.title}*! :moneybag:"
      SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?
    else
      redirect_to project_path(@project), alert: "Failed to stake stonks"
    end
  end

  def unstake_stonks
    @project = Project.find(params[:id])

    @stonk = Stonk.find_by(user: current_user, project: @project)

    if @stonk.nil?
      redirect_to project_path(@project), alert: "You do not have any stonks to unstake"
      return
    end

    if @stonk.destroy
      redirect_to project_path(@project), notice: "Successfully unstaked all your stonks"
    else
      redirect_to project_path(@project), alert: "Failed to unstake stonks"
    end
  end

  def destroy
    Project.transaction do
      @project.stonks.destroy_all
      @project.project_follows.destroy_all

      raise ActiveRecord::Rollback unless @project.update(is_deleted: true)
    end

    if @project.is_deleted?
      redirect_to my_projects_path, notice: "Project was successfully deleted along with all stonks."
    else
      redirect_to project_path(@project), alert: "Could not delete project."
    end
  end

  def update_coordinates
    authorize @project, :update_coordinates?

    unless @project.shipped_once?
      return render json: { error: "Project must be shipped at least once to be placed on the map." }, status: :unprocessable_entity
    end

    if @project.update(coordinates_params)
      render json: { success: true, project: { id: @project.id, x: @project.x, y: @project.y } }
    else
      render json: { success: false, errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def unplace_coordinates
    authorize @project, :update_coordinates?

    if @project.update(x: nil, y: nil)
      render json: { success: true, project: { id: @project.id, x: nil, y: nil } }
    else
      render json: { success: false, errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Admin methods
  # def recover
  #     deleted_project = Project.with_deleted.find_by(id: params[:id])
  #     if deleted_project && deleted_project.is_deleted? && current_user.admin?
  #         if deleted_project.update(is_deleted: false)
  #             redirect_to project_path(deleted_project), notice: "Project has been recovered."
  #         else
  #             redirect_to projects_path, alert: "Could not recover project."
  #         end
  #     else
  #         redirect_to projects_path, alert: "Project not found or cannot be recovered."
  #     end
  # end

  private

  def compute_ship_event_data
    ship_event_data = {}
    ship_events_by_date = @ship_events.sort_by(&:created_at)
    devlogs_by_date = @devlogs.sort_by(&:created_at)

    ship_events_by_date.each_with_index do |ship_event, index|
      position = index + 1
      payouts = ship_event.payouts.where(escrowed: false).to_a
      payout_count = payouts.size
      payout_sum = payouts.sum(&:amount)

      escrowed_payouts = ship_event.payouts.where(escrowed: true).to_a
      escrow_count = escrowed_payouts.size
      escrow_sum = escrowed_payouts.sum(&:amount)

      if index == 0
        devlogs_count = devlogs_by_date.count do |devlog|
          devlog.created_at <= ship_event.created_at
        end
      else
        previous_ship = ship_events_by_date[index - 1]
        devlogs_count = devlogs_by_date.count do |devlog|
          devlog.created_at > previous_ship.created_at && devlog.created_at <= ship_event.created_at
        end
      end

      ship_event_data[ship_event.id] = {
        position: position,
        payout_count: payout_count,
        payout_sum: payout_sum,
        escrow_count: escrow_count,
        escrow_sum: escrow_sum,
        devlogs_since_last_count: devlogs_count,
        hours_covered: helpers.format_seconds(ship_event.seconds_covered)
      }
    end

    ship_event_data
  end

  def pj_image
    if @project.banner.attached?
      url_for(@project.banner)
    else
      devlog_with_image = @devlogs.find { |devlog| devlog.file.attached? && devlog.file.image? }
      if devlog_with_image
        url_for(devlog_with_image.file)
      else
        "https://summer.hackclub.com/social-splash.jpg"
      end
    end
  end

  def ysws_type_options
    [ [ "Select a YSWS program...", "" ] ] + Project.ysws_types.map { |key, value| [ value, value ] }
  end
  helper_method :ysws_type_options

  private

  def check_identity_verification
    return if current_user&.identity_vault_id.present? && current_user.verification_status != :ineligible

    redirect_to campfire_path, alert: "Please verify your identity to access this page."
  end

  def require_hackatime
    return if current_user&.has_hackatime?

    redirect_to my_projects_path, alert: "You must link your HackaTime account before creating a project. Please go to Settings to link your account."
  end

  def set_project
    @project = Project.includes(
      {
        user: [ :user_hackatime_data, :user_badges ],
        devlogs: [
          { user: :user_badges },
          { comments: :user },
          { file_attachment: :blob }
        ],
        ship_events: [
          :payouts
        ],
        stonks: [
          :user
        ],
        followers: :projects
      },
      { banner_attachment: :blob },
      ship_certifications: [ { proof_video_attachment: :blob } ]
    ).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    deleted_project = Project.with_deleted.find_by(id: params[:id])
    if deleted_project&.is_deleted?
      redirect_to projects_path, alert: "This project has been deleted."
    else
      redirect_to projects_path, alert: "Project not found."
    end
  end

  def check_if_shipped
    return unless @project.is_shipped?

    redirect_to project_path(@project), alert: "This project has been shipped and cannot be edited."
  end

  def authorize_user
    return if current_user == @project.user

    redirect_to project_path(@project), alert: "You can only delete your own projects."
  end

  def project_params
    params.expect(project: [ :title, :description, :used_ai, :readme_link, :demo_link, :repo_link,
                             :banner, :ysws_submission, :ysws_type, :category, :certification_type, { hackatime_project_keys: [] } ])
  end

  def coordinates_params
    params.require(:project).permit(:x, :y)
  end

  def not_img?(banner)
    return false if banner.blank?
    if banner.respond_to?(:content_type)
      !banner.content_type.start_with?("image/")
    else
      false
    end
  end
end
