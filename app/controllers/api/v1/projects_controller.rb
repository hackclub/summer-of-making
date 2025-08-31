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
          # ?devlogs=true
          include_devlogs = params[:devlogs] == "true"

          base_scope = Project.where(is_deleted: false)
                               .includes(:user, :followers, banner_attachment: :blob)
                               .order(:id)

          base_scope = base_scope.includes(devlogs: [ :comments, { file_attachment: :blob } ]) if include_devlogs

          pagy, projects = pagy(
            base_scope,
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        devlog_ids_by_project = {}
        total_seconds_by_project = {}
        unless include_devlogs
          project_ids = projects.map(&:id)
          if project_ids.any?
            Devlog.where(project_id: project_ids).pluck(:project_id, :id).each do |pid, did|
              (devlog_ids_by_project[pid] ||= []) << did
            end
            total_seconds_by_project = Devlog.where(project_id: project_ids).group(:project_id).sum(:duration_seconds)
          end
        end

        @projects = projects.map do |project|
          {
            id: project.id,
            title: project.title,
            description: project.description,
            category: project.category,
            devlogs_count: project.devlogs_count,
            devlogs:
              if include_devlogs
                project.devlogs.map do |d|
                  {
                    id: d.id,
                    text: d.text,
                    attachment: d.file.present? ? url_for(d.file) : nil,
                    time_seconds: d.duration_seconds,
                    likes_count: d.likes_count,
                    comments_count: d.comments_count,
                    comments: d.comments.map { |c| { id: c.id, content: c.content, user_id: c.user_id, created_at: c.created_at } },
                    created_at: d.created_at,
                    updated_at: d.updated_at
                  }
                end
              else
                devlog_ids_by_project[project.id] || []
              end,
            total_seconds_coded: include_devlogs ? project.total_seconds_coded : (total_seconds_by_project[project.id] || 0),
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
        begin
          @project = Project.includes(:user, :followers, { banner_attachment: :blob }, devlogs: [ :comments, { file_attachment: :blob } ]).find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "project does not exist" }, status: :not_found
          return
        end
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
                  attachment: d.file.present? ? url_for(d.file) : nil,
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

      def shipped
        stuff = Project.joins(:ship_events)
                        .where(is_deleted: false)
                        .group("projects.id")
                        .order("MAX(ship_events.created_at) DESC")
                        .limit(25)
                        .pluck("projects.id", "MAX(ship_events.created_at)")

        project_ids = stuff.map(&:first)

        shit = Project.includes(:user, :followers, :ship_events, banner_attachment: :blob)
                      .where(id: project_ids)
                      .index_by(&:id)

        s = Devlog.where(project_id: project_ids)
                  .group(:project_id)
                  .sum(:duration_seconds)

        @out = stuff.map do |project_id, latest_ship_date|
          project = shit[project_id]
          next unless project

          {
            id: project.id,
            title: project.title,
            description: project.description,
            devlogs_count: project.devlogs_count,
            total_seconds_coded: s[project.id] || 0,
            is_shipped: project.is_shipped, # if its no, we fucked up
            readme_link: project.readme_link,
            demo_link: project.demo_link,
            repo_link: project.repo_link,
            user_id: project.user.id,
            slack_id: project.user.slack_id,
            created_at: project.created_at,
            updated_at: project.updated_at,
            latest_ship_date: latest_ship_date,
            total_ships: project.ship_events.count
          }
        end.compact

        render json: @out
      end
    end
  end
end
