# frozen_string_literal: true

module Api
  module V1
    class DevlogsController < ApplicationController
      include Pagy::Backend

      def index
        page = Integer(params[:page], exception: false) || 1
        page = 1 if page < 1
        if page < 1
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        begin
          pagy, devlogs = pagy(
            Devlog.order(:id).includes(:user, :project, file_attachment: :blob),
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @devlogs = devlogs.map do |devlog|
          {
            text: devlog.text,
            id: devlog.id,
            attachment: devlog.file.attached? ? url_for(devlog.file) : nil,
            project_id: devlog.project_id,
            slack_id: devlog.user&.slack_id,
            created_at: devlog.created_at,
            updated_at: devlog.updated_at
          }
        end

        render json: {
          devlogs: @devlogs,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @devlog = Devlog.includes(:user, :project, file_attachment: :blob).find(params[:id])
        render json: {
          text: @devlog.text,
          id: @devlog.id,
          attachment: @devlog.file.attached? ? url_for(@devlog.file) : nil,
          project_id: @devlog.project_id,
          slack_id: @devlog.user&.slack_id,
          created_at: @devlog.created_at,
          updated_at: @devlog.updated_at
        }
      end
    end
  end
end
