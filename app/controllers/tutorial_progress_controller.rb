# frozen_string_literal: true

class TutorialProgressController < ApplicationController
  before_action :authenticate_user!

  def complete_step
    step_name = params[:step_name]

    if step_name.present?
      current_user.tutorial_progress.complete_step!(step_name)
      redirect_back(fallback_location: root_path)
    else
      redirect_back(fallback_location: root_path, alert: "Invalid step")
    end
  end

  def complete_soft_step
    step_name = params[:step_name]

    if step_name.present?
      current_user.tutorial_progress.complete_soft_step!(step_name)

      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: "Invalid step") }
        format.json { render json: { error: "Invalid step" }, status: :bad_request }
      end
    end
  end
end
