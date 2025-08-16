# frozen_string_literal: true

module Api
  module V2
    class BaseController < ApplicationController
      include Pagy::Backend
      protect_from_forgery with: :null_session

      def index
        render json: { ur: "mom" }
      end

      private

      def render_paginated(collection, serializer_options = {})
        pagy, records = pagy(collection, items: 20)

        data = if block_given?
          records.map { |record| yield(record) }
        else
          records
        end

        render json: {
          data: data,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      rescue Pagy::OverflowError
        render json: { error: "not found" }, status: :not_found
      end

      def render_not_found(message = "not found")
        render json: { error: message }, status: :not_found
      end
    end
  end
end
