# frozen_string_literal: true

module Api
  module V1
    class CommentsController < ApplicationController
      def index
        @comments = Comment.includes(:user)
                          .select(:id, :rich_content, :devlog_id, :created_at, :user_id)
                          .map do |comment|
          {
            text: comment.display_content,
            devlog_id: comment.devlog_id,
            slack_id: comment.user.slack_id,
            created_at: comment.created_at
          }
        end
        render json: @comments
      end

      def show
        @comment = Comment.includes(:user)
                         .select(:id, :rich_content, :devlog_id, :created_at, :user_id)
                         .find(params[:id])
        render json: {
          text: @comment.display_content,
          devlog_id: @comment.devlog_id,
          slack_id: @comment.user.slack_id,
          created_at: @comment.created_at
        }
      end
    end
  end
end
