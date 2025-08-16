# frozen_string_literal: true

module Api
  module V2
    class UsersController < BaseController
      def index
        users = User.includes(:user_profile)
                   .order(:id)

        render_paginated(users) do |user|
          iu(user)
        end
      end

      def show
        user = User.includes(:user_profile, :user_hackatime_data, :user_badges, :projects)
                  .find_by(id: params[:id])

        return render_not_found("not found") unless user

        render json: su(user)
      end

      def search
        query = params[:q]&.strip
        return render json: { error: "what u searchin for?" }, status: :bad_request if query.blank?

        users = User.joins(:user_profile)
        .where("users.display_name ILIKE ? OR users.slack_id ILIKE ? OR user_profiles.bio ILIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%")
        .includes(:user_profile)
        .order(:id)

        render_paginated(users) do |user|
          iu(user)
        end
      end

      private

      def iu(user)
        {
          id: user.id,
          slack_id: user.slack_id,
          display_name: user.display_name,
          bio: user.user_profile&.bio,
          projects_count: user.projects.size,
          devlogs_count: user.devlogs.count,
          avatar: user.avatar,
          created_at: user.created_at
        }
      end

      def su(user)
        {
          id: user.id,
          slack_id: user.slack_id,
          display_name: user.display_name,
          bio: user.user_profile&.bio,
          projects_count: user.projects.size,
          devlogs_count: user.devlogs.count,
          votes_count: user.votes.count,
          projects: user.projects.map { |p|
            { id: p.id, title: p.title, devlogs_count: p.devlogs.count, created_at: p.created_at }
          },
          coding_time_seconds: user.has_hackatime? ? user.all_time_coding_seconds : 0,
          coding_time_seconds_today: user.has_hackatime? ? user.daily_coding_seconds : 0,
          badges: user.badges.map { |b|
            icon = b[:icon].include?(".") ? view_context.image_url(b[:icon]) : b[:icon]
            { name: b[:name], text: b[:flavor_text], icon: icon }
          },
          created_at: user.created_at,
          updated_at: user.updated_at,
          avatar: user.avatar,
          custom_css: user.user_profile&.custom_css
        }
      end
    end
  end
end
