# frozen_string_literal: true

module Admin
  class ProjectsController < ApplicationController
    before_action :set_project, only: [ :destroy, :restore, :magic_is_happening ]

    def destroy
      @project.update!(is_deleted: true)

      @project.create_activity(
        "admin_delete_project",
        owner: current_user,
        parameters: {
          admin_name: current_user.display_name,
          project_name: @project.title,
          project_id: @project.id
        }
      )

      flash[:success] = "#{@project.title} terminated, your project is ass"
      redirect_back(fallback_location: admin_root_path)
    end

    def restore
      @project.update!(is_deleted: false)

      @project.create_activity(
        "admin_restore_project",
        owner: current_user,
        parameters: {
          admin_name: current_user.display_name,
          project_name: @project.title,
          project_id: @project.id
        }
      )

      flash[:success] = "#{@project.title} is back in black!"
      redirect_back(fallback_location: admin_root_path)
    end

    def magic_is_happening
      @project.magic_happening!
      flash[:success] = "posted!!"
      redirect_back(fallback_location: admin_project_path(@project))
    end

    private

    def set_project
      @project = Project.with_deleted.find(params[:id])
    end
  end
end
