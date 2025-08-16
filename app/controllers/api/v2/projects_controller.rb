# frozen_string_literal: true

module Api
  module V2
    class ProjectsController < BaseController
      def index
        projects = Project.where(is_deleted: false)
                          .includes(:user, banner_attachment: :blob)
                          .order(id: :desc)

        render_paginated(projects) do |project|
          ip(project)
        end
      end

      def show
        project = Project.includes(:user, :followers, banner_attachment: :blob,
                                  devlogs: [ :comments, { file_attachment: :blob } ])
                         .find_by(id: params[:id])

        return render_not_found("not found") unless project

        render json: sp(project)
      end

      def search
        query = params[:q]&.strip
        return render json: { error: "what u searchin for?" }, status: :bad_request if query.blank?

        projects = Project.where(is_deleted: false)
                          .where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
                          .includes(:user, banner_attachment: :blob)
                          .order(id: :desc)

        render_paginated(projects) do |project|
          ip(project)
        end
      end

      private

      def ip(project)
        {
          id: project.id,
          title: project.title,
          description: project.description,
          category: project.category,
          devlogs_count: project.devlogs.count,
          banner: project.banner.attached? ? url_for(project.banner) : nil,
          user: {
            id: project.user.id,
            display_name: project.user.display_name
          },
          created_at: project.created_at
        }
      end

      def sp(project)
        {
          id: project.id,
          title: project.title,
          description: project.description,
          category: project.category,
          devlogs_count: project.devlogs.count,
          total_seconds_coded: project.total_seconds_coded,
          readme_link: project.readme_link,
          demo_link: project.demo_link,
          repo_link: project.repo_link,
          user_id: project.user.id,
          slack_id: project.user.slack_id,
          created_at: project.created_at,
          updated_at: project.updated_at,
          banner: project.banner.attached? ? url_for(project.banner) : nil,
          followers: project.followers.map { |u| { id: u.id, name: u.display_name } },
          devlogs: project.devlogs.map do |devlog|
        {
          id: devlog.id,
          text: devlog.text,
          attachment: devlog.file.present? ? url_for(devlog.file) : nil,
          time_seconds: devlog.duration_seconds,
          likes_count: devlog.likes_count,
          comments_count: devlog.comments_count,
          comments: devlog.comments.map { |c|
            { id: c.id, content: c.content, user_id: c.user_id, created_at: c.created_at }
          },
          created_at: devlog.created_at,
          updated_at: devlog.updated_at
        }
          end
        }
      end
    end
  end
end
