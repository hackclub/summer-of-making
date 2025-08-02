# frozen_string_literal: true

# Provides more detailed info about projects, especially the long requested banner_url
# Provides the x, y, counts, hours, followers, etc.
# By adding a ?devlogs=true parameter, it will also provide devlogs on a project + comments

module Api
  module V1
    class ProjectsController < ApplicationController
      include Pagy::Backend
      before_action :authenticate_user! # fucking over the api clients

      def index
        page = Integer(params[:page], exception: false) || 1
        page = 1 if page < 1
        begin
          pagy, projects = pagy(
            Project.where(is_deleted: false)
                  .includes(:user, :followers, devlogs: [ :comments, file_attachment: :blob ])
                  .order(:id),
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @projects = projects.map do |project|
          {
            id: project.id,
            title: project.title,
            description: project.description,
            category: project.category,
            devlogs_count: project.devlogs_count,
            devlogs:
              if params[:devlogs] == "true"
                project.devlogs.map do |d|
                  {
                    id: d.id,
                    text: d.text,
                    attachment: url_for(d.file),
                    time_seconds: d.duration_seconds,
                    likes_count: d.likes_count,
                    comments_count: d.comments_count,
                    comments: d.comments.map { |c| { id: c.id, content: c.content, user_id: c.user_id, created_at: c.created_at } },
                    created_at: d.created_at,
                    updated_at: d.updated_at
                  }
                end
              else
                project.devlogs.pluck(:id)
              end,
            total_seconds_coded: project.total_seconds_coded,
            is_shipped: project.is_shipped,
            readme_link: project.readme_link,
            demo_link: project.demo_link,
            repo_link: project.repo_link,
            user_id: project.user.id,
            slack_id: project.user.slack_id,
            x: project.x,
            y: project.y,
            created_at: project.created_at,
            updated_at: project.updated_at,
            banner: project.banner.attached? ? url_for(project.banner) : nil,
            followers: project.followers.map { |u| { id: u.id, name: u.display_name } }
          }
        end

        render json: {
          projects: @projects,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @project = Project.includes(:user, :followers, devlogs: [ :comments, file_attachment: :blob ]).find(params[:id])
        render json: {
          id: @project.id,
          title: @project.title,
          description: @project.description,
          category: @project.category,
          devlogs_count: @project.devlogs_count,
          devlogs:
              @project.devlogs.map do |d|
                {
                  id: d.id,
                  text: d.text,
                  attachment: url_for(d.file),
                  time_seconds: d.duration_seconds,
                  likes_count: d.likes_count,
                  comments_count: d.comments_count,
                  comments: d.comments.map { |c| { id: c.id, content: c.content, user_id: c.user_id, created_at: c.created_at } },
                  created_at: d.created_at,
                  updated_at: d.updated_at
                }
              end,
          total_seconds_coded: @project.total_seconds_coded,
          is_shipped: @project.is_shipped,
          readme_link: @project.readme_link,
          demo_link: @project.demo_link,
          repo_link: @project.repo_link,
          user_id: @project.user.id,
          slack_id: @project.user.slack_id,
          x: @project.x,
          y: @project.y,
          created_at: @project.created_at,
          updated_at: @project.updated_at,
          banner: @project.banner.attached? ? url_for(@project.banner) : nil,
          followers: @project.followers.map { |u| { id: u.id, name: u.display_name } }
        }
      end
    end
  end
end
