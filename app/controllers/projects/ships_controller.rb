class Projects::ShipsController < ApplicationController
  before_action :set_project

  def create
    authorize @project, :ship?

    # Verify all requirements are met
    errors = @project.shipping_errors
    if errors.any?
      redirect_to project_path(@project), alert: "Cannot ship project: #{errors.join(' ')}"
      return
    end

    if (ship_event = ShipEvent.create(project: @project)).persisted?
      is_first_ship = current_user.projects.joins(:ship_events).count == 1
      ahoy.track "tutorial_step_first_project_shipped", user_id: current_user.id, project_id: @project.id, is_first_ship: is_first_ship
      redirect_to project_path(@project), notice: "Your project has been shipped!"

      message = "Congratulations on shipping your project! Now thy project shall fight for blood :ultrafastparrot:"
      SendSlackDmJob.perform_later(@project.user.slack_id, message) if @project.user.slack_id.present?
    else
      redirect_to project_path(@project), alert: ship_event.errors.full_messages.to_sentence
    end
  end

  private

  def set_project
    @project = Project.includes(:user).find(params[:project_id])
  end
end
