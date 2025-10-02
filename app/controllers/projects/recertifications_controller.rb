class Projects::RecertificationsController < ApplicationController
  before_action :set_project

  def create
    authorize @project, :request_recertification?

    deadline = local(2025, 10, 2, 23, 59, 59)
    if Time.current > deadline
      if current_user.has_permission?("post_deadline_recert_used")
        current_user.add_permission("no_recert")
        redirect_to project_path(@project), alert: "You already used your one post-deadline recert chance."
        return
      else
        current_user.add_permission("post_deadline_recert_used")
      end
    end

    instructions = params[:recertification_instructions]

    if @project.request_recertification!(instructions)
      if Time.current > deadline
        redirect_to project_path(@project), notice: "Last Re-certification requested! Your project will be reviewed again."
      else
        redirect_to project_path(@project), notice: "Re-certification requested! Your project will be reviewed again."
      end
    else
      redirect_to project_path(@project), alert: "Cannot request re-certification for this project."
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
