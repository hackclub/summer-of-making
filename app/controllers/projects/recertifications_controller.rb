class Projects::RecertificationsController < ApplicationController
  before_action :set_project

  def create
    authorize @project, :request_recertification?

    if current_user.recertification_blocked?
      redirect_to project_path(@project), alert: "Nice try but you're blocked from requesting recerts"
      return
    end

    deadline = Time.zone.parse("2025-10-02 23:59:59 EST")
    if Time.current > deadline
      current_user.add_permission("no_recert")
      redirect_to project_path(@project), alert: "Summer of Making is over! You used your one post-deadline recert request."
      return
    end

    instructions = params[:recertification_instructions]

    if @project.request_recertification!(instructions)
      redirect_to project_path(@project), notice: "Re-certification requested! Your project will be reviewed again."
    else
      redirect_to project_path(@project), alert: "Cannot request re-certification for this project."
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
