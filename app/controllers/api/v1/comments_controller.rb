# frozen_string_literal: true

module Api
  module V1
    class CommentsController < ApplicationController
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
          pagy, comments = pagy(
            Comment.order(:id).includes(:user, :devlog),
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @comments = comments.map do |comment|
          {
            text: comment.content,
            devlog_id: comment.devlog_id,
            slack_id: comment.user&.slack_id,
            created_at: comment.created_at
          }
        end

        render json: {
          comments: @comments,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @comment = Comment.includes(:user, :devlog).find(params[:id])
        render json: {
          text: @comment.content,
          devlog_id: @comment.devlog_id,
          slack_id: @comment.user&.slack_id,
          created_at: @comment.created_at
        }
      end
    end
  end
end
