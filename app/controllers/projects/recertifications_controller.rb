class Projects::RecertificationsController < ApplicationController
  before_action :set_project

  def create
    authorize @project, :request_recertification?

    # Post-deadline recertification logic:
    # After the deadline, users are granted exactly one additional recertification attempt.
    # If they've already used this "grace" attempt (post_deadline_recert_used permission),
    # they are permanently blocked from requesting more recertifications (no_recert permission).
    # This provides a fair one-time extension while preventing indefinite recertification requests.
    deadline = Rails.application.config.x.recertification_deadline
    if Time.current > deadline
      if current_user.has_permission?("post_deadline_recert_used")
        current_user.add_permission("no_recert")
        Rails.logger.info("[Recertification] User #{current_user.id} blocked from recerts after using post-deadline attempt")
        redirect_to project_path(@project), alert: "You already used your one post-deadline recert chance."
        return
      else
        current_user.add_permission("post_deadline_recert_used")
        Rails.logger.info("[Recertification] User #{current_user.id} using post-deadline recert attempt for project #{@project.id}")
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
