class Projects::RecertificationsController < ApplicationController
  before_action :set_project

  def create
    authorize @project, :request_recertification?

    if @project.request_recertification!
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
