# frozen_string_literal: true

class DevlogsController < ApplicationController
  include ActionView::RecordIdentifier
  include ViewTrackable
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_project, only: %i[create destroy update]
  before_action :set_devlog, only: %i[show destroy update]
  before_action :check_if_shipped, only: %i[create destroy update]
  skip_before_action :authenticate_user!, only: [ :api_create ]
  before_action :authenticate_api_key, only: [ :api_create ]
  skip_before_action :verify_authenticity_token, only: [ :api_create ]
  def show
    # track_view(@devlog)
  end

  def index
    @page = [ params[:page].to_i, 1 ].max
    @per_page = 10

    @devlogs = Devlog.includes(:project, :user)
                     .where(project_id: current_user.followed_projects.pluck(:id))
                     .order(created_at: :desc)
                     .offset((@page - 1) * @per_page)
                     .limit(@per_page)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @project = Project.find(params[:project_id])

    unless current_user == @project.user
      redirect_to project_path(@project), alert: "wuh"
      return
    end

    # check time reqs
    unless @project.can_post_devlog?
      redirect_to project_path(@project), alert: "You can't post a devlog right now."
      return
    end

    @devlog = @project.devlogs.build(devlog_params)
    @devlog.user = current_user

    # set hackatime data
    if @project.hackatime_keys.present?
      @devlog.hackatime_projects_key_snapshot = @project.hackatime_keys
      @devlog.hackatime_pulled_at = Time.current
    end

    @devlog.for_sinkening = true if Flipper.enabled?(:sinkening, current_user)

    if @devlog.save
      if @project.hackatime_keys.present?
        @devlog.recalculate_seconds_coded
      end

      if @devlog.project
        flash[:new_devlog_id] = @devlog.id
        redirect_to @devlog.project, notice: "Devlog was successfully posted."
      else
        flash[:new_devlog_id] = @devlog.id
        redirect_to campfire_path, notice: "Devlog was successfully posted."
      end
    else
      if @devlog.project
        redirect_to @devlog.project, alert: "Failed to post devlog."
      else
        redirect_to campfire_path, alert: "Failed to post devlog."
      end
    end
  end

  def update
    authorize @devlog
    if @devlog.user != current_user
      flash.now[:alert] = "You can only edit your own devlogs."
      if @devlog.project
        redirect_to @devlog.project, alert: "You can only edit your own devlogs."
      else
        redirect_to campfire_path, alert: "You can only edit your own devlogs."
      end
      return
    end

    # Only allow editing the text field
    if @devlog.update(devlog_params.slice(:text))
      if @devlog.project
        redirect_to @devlog.project, notice: "Devlog was successfully edited."
      else
        redirect_to campfire_path, notice: "Devlog was successfully edited."
      end
    else
      if @devlog.project
        redirect_to @devlog.project, alert: "Failed to edit devlog."
      else
        redirect_to campfire_path, alert: "Failed to edit devlog."
      end
    end
  end

  def destroy
    if @devlog.user != current_user
      if @devlog.project
        redirect_to @devlog.project, alert: "You can only delete your own devlogs."
      else
        redirect_to campfire_path, alert: "You can only delete your own devlogs."
      end
      return
    end

    if @devlog.user_advent_sticker
      if @devlog.project
        redirect_to @devlog.project, alert: "This devlog has an earned sticker and cannot be deleted."
      else
        redirect_to campfire_path, alert: "This devlog has an earned sticker and cannot be deleted."
      end
      return
    end

    if @devlog.covered_by_ship_event?
      if @devlog.project
        redirect_to @devlog.project, alert: "This devlog is covered by a ship event and cannot be deleted."
      else
        redirect_to campfire_path, alert: "This devlog is covered by a ship event and cannot be deleted."
      end
      return
    end

    @devlog.soft_delete!
    if @devlog.project
      redirect_to @devlog.project, notice: "Devlog was successfully deleted."
    else
      redirect_to campfire_path, notice: "Devlog was successfully deleted."
    end
  end

  def api_create
    if ENV["UPDATES_STATUS"] == "locked"
      return render json: { error: "Posting devlogs is currently locked" }, status: :forbidden
    end

    user = User.find_by(slack_id: params[:slack_id])
    return render json: { error: "User not found" }, status: :not_found unless user

    project = Project.find_by(id: params[:project_id])
    return render json: { error: "Project not found" }, status: :not_found unless project

    # Check if the user owns the project
    unless user == project.user
      return render json: { error: "You can only post devlogs to your own projects" }, status: :forbidden
    end

    devlog = project.devlogs.build(devlog_params)
    devlog.user = user

    devlog.for_sinkening = true if Flipper.enabled?(:sinkening, user)

    if devlog.save
      render json: { message: "Devlog successfully created", devlog: devlog }, status: :created
    else
      render json: { error: "Failed to create devlog", details: devlog.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def set_devlog
    if @project
      @devlog = @project.devlogs
                         .with_attached_file
                         .includes(user_advent_sticker: { shop_item: [ { image_attachment: :blob }, { silhouette_image_attachment: :blob } ] })
                         .find(params[:id])
    else
      @devlog = Devlog
                  .with_attached_file
                  .includes(user_advent_sticker: { shop_item: [ { image_attachment: :blob }, { silhouette_image_attachment: :blob } ] })
                  .find(params[:id])
       @project = @devlog.project
    end
  end

  def check_if_shipped
    return unless @project&.is_shipped?

    redirect_to @project, alert: "This project has been shipped and cannot be modified."
  end

  def authenticate_api_key
    api_key = request.headers["Authorization"]
    return if api_key.present? && api_key == ENV["API_KEY"]

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def devlog_params
    params.expect(devlog: %i[text file for_sinkening])
  end
end
