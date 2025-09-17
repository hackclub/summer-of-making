class Projects::FollowsController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :authenticate_user!
  before_action :set_project

  def create
    @project_follow = current_user.project_follows.build(project: @project)

    if @project_follow.save
      handle_response("You are now following this project!", :notice, true)
    else
      handle_response(@project_follow.errors.full_messages.join(", "), :alert, false)
    end
  end

  def destroy
    @project_follow = current_user.project_follows.find_by(project: @project)

    if @project_follow.destroy
      handle_response("You have unfollowed this project.", :notice, false)
    else
      handle_response(@project_follow.errors.full_messages.join(", "), :alert, true)
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authenticate_user!
    redirect_to new_user_session_path unless user_signed_in?
  end

  def handle_response(message, flash_type, following_state)
    respond_to do |format|
      format.html { redirect_to @project, flash_type => message }
      format.turbo_stream { render_turbo_response(message, flash_type, following_state) }
    end
  end

  def render_turbo_response(message, flash_type, following_state)
    flash.now[flash_type] = message
    render turbo_stream: [
      turbo_stream.update("flash-container", partial: "shared/flash"),
      turbo_stream.replace(dom_id(@project, :follow_button),
                           partial: "projects/follow_button",
                           locals: { project: @project, following: following_state })
    ]
  end
end
