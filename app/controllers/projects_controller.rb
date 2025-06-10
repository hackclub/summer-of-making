# frozen_string_literal: true

class ProjectsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!, except: %i[index show]
  before_action :set_project,
                only: %i[show edit update follow unfollow ship stake_stonks unstake_stonks destroy]
  before_action :check_if_shipped, only: %i[edit update]
  before_action :authorize_user, only: [ :destroy ]
  before_action :require_hackatime, only: [ :create ]

  def index
    if params[:action] == "my_projects"
      @projects = Project.includes(:user)
                         .where.not(user_id: current_user.id)
                         .order(rating: :asc)

      # @projects = @projects.sort_by do |project|
      #     weight = rand + (project.updates.count > 0 ? 1.5 : 0)
      #     -weight
      # end

      @show_create_project = true if @projects.empty?
    elsif params[:tab] == "gallery"
      @projects = Project.includes(:user)
                         .order(rating: :asc)

      @projects = @projects.sort_by do |project|
        weight = rand + (project.devlogs.count.positive? ? 1.5 : 0)
        -weight
      end
    elsif params[:tab] == "following"
      @followed_projects = current_user.followed_projects.includes(:user)
      @recent_devlogs = Devlog.joins(:project)
                              .includes(:project, :user)
                              .where(project_id: @followed_projects.pluck(:id))
                              .where(projects: { is_deleted: false })
                              .order(created_at: :desc)

      @pagy, @recent_devlogs = pagy(@recent_devlogs, items: 5)
    elsif params[:tab] == "stonked"
      @stonked_projects = current_user.staked_projects.includes(:user)
      @recent_devlogs = Devlog.joins(:project)
                              .includes(:project, :user)
                              .where(project_id: @stonked_projects.pluck(:id))
                              .where(projects: { is_deleted: false })
                              .order(created_at: :desc)

      @pagy, @recent_devlogs = pagy(@recent_devlogs, items: 5)
    else
      devlogs_query = Devlog.joins(:project)
                            .includes(:project, :user, comments: :user)
                            .where(projects: { is_deleted: false })
                            .order(created_at: :desc)

      @pagy, @recent_devlogs = pagy(devlogs_query, items: 5)

      @projects = Project.includes(:user).order(rating: :asc)
      @projects = @projects.sort_by do |project|
        weight = rand + (project.devlogs.count.positive? ? 1.5 : 0)
        -weight
      end
    end
  end

  def show
    @devlogs = @project.devlogs
    @ship_events = @project.ship_events
    @timeline = (@devlogs + @ship_events).sort_by(&:created_at)

    @stonks = @project.stonks.includes(:user).order(amount: :desc)

    return unless current_user

    @user_stonk = @project.stonks.find_by(user: current_user)
  end

  def edit
    return if current_user == @project.user

    redirect_to project_path(@project), alert: "You can only edit your own projects."
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.hackatime_project_keys.present?
      @project.hackatime_project_keys = @project.hackatime_project_keys.compact_blank.uniq
    end

    if @project.save
      redirect_to project_path(@project), notice: "Project was successfully created."
    else
      flash.now[:alert] = "Could not create project. Please check the form for errors."
      render :index, status: :unprocessable_entity
    end
  end

  def update
    if current_user == @project.user
      update_params = project_params

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
    @projects = current_user.projects.order(created_at: :desc)
    @show_create_project = true

    current_user.refresh_hackatime_data if current_user.has_hackatime?

    render :index
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

    if ShipEvent.create(project: @project)
      redirect_to project_path(@project), notice: "Your project has been shipped!"

      message = "Congratulations on shipping your project! Now thy project shall fight for blood :ultrafastparrot:"
      SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?
    else
      redirect_to project_path(@project), alert: "Could not ship project."
    end
  end

  # Some AI generated code to check if a link is a valid repo or readme link
  def check_link
    url = params[:url]
    link_type = params[:link_type]

    require "net/http"
    require "uri"

    begin
      uri = URI.parse(url)
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
      when 200..299
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
      # delete all active timer sessions for this project (otherwise it bricks and you can't start new timers)
      @project.timer_sessions.where(status: %i[running paused]).destroy_all

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

  def require_hackatime
    return if current_user&.has_hackatime?

    redirect_to my_projects_path, alert: "You must link your HackaTime account before creating a project. Please go to Settings to link your account."
  end

  def set_project
    @project = Project.includes(:user, devlogs: :user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    deleted_project = Project.with_deleted.find_by(id: params[:id])
    if deleted_project&.is_deleted?
      redirect_to projects_path, alert: "This project has been deleted by its owner."
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
    permitted_params = params.expect(project: [ :title, :description, :readme_link, :demo_link, :repo_link,
                                                :banner, { hackatime_project_keys: [] } ])

    permitted_params.merge!(params.expect(project: [ :category ])) if action_name == "create"

    permitted_params
  end
end
