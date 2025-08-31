# frozen_string_literal: true

module Api
  module V2
    class DevlogsController < BaseController
      def index
        devlogs = Devlog.includes(:user, :project, file_attachment: :blob)
                        .order(id: :desc)

        render_paginated(devlogs) do |devlog|
          is(devlog)
        end
      end

      def show
        devlog = Devlog.includes(:user, :project, :comments, file_attachment: :blob)
                      .find_by(id: params[:id])

        return render_not_found("not found") unless devlog

        render json: ss(devlog)
      end

      private

      def is(devlog)
        {
          id: devlog.id,
          text: devlog.text,
          attachment: devlog.file.present? ? url_for(devlog.file) : nil,
          duration_seconds: devlog.duration_seconds,
          likes_count: devlog.likes_count,
          comments_count: devlog.comments_count,
          project: {
            id: devlog.project.id,
            title: devlog.project.title
          },
          user: {
            id: devlog.user.id,
            display_name: devlog.user.display_name
          },
          created_at: devlog.created_at
        }
      end

      def ss(devlog)
        {
          id: devlog.id,
          text: devlog.text,
          attachment: devlog.file.present? ? url_for(devlog.file) : nil,
          duration_seconds: devlog.duration_seconds,
          likes_count: devlog.likes_count,
          comments_count: devlog.comments_count,
          project: {
            id: devlog.project.id,
            title: devlog.project.title
          },
          user: {
            id: devlog.user.id,
            slack_id: devlog.user.slack_id,
            display_name: devlog.user.display_name
          },
          comments: devlog.comments.map do |comment|
            {
              id: comment.id,
              content: comment.content,
              user_id: comment.user_id,
              created_at: comment.created_at
            }
          end,
          created_at: devlog.created_at,
          updated_at: devlog.updated_at
        }
      end
    end
  end
end
