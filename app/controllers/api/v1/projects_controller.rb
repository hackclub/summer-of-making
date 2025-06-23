# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < ApplicationController
      def index
        @projects = Project.all.map do |project|
          {
            id: project.id,
            title: project.title,
            description: project.description,
            category: project.category,
            readme_link: project.readme_link,
            demo_link: project.demo_link,
            repo_link: project.repo_link,
            slack_id: project.user.slack_id,
            created_at: project.created_at,
            updated_at: project.updated_at
          }
        end
        render json: @projects
      end

      def show
        @project = Project.find(params[:id])
        render json: {
          id: @project.id,
          title: @project.title,
          description: @project.description,
          category: @project.category,
          readme_link: @project.readme_link,
          demo_link: @project.demo_link,
          repo_link: @project.repo_link,
          slack_id: @project.user.slack_id,
          created_at: @project.created_at,
          updated_at: @project.updated_at
        }
      end
    end
  end
end
