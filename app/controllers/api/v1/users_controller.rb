# frozen_string_literal: true

# API endpoint added by Alimadcorp & changed slightly by SabioOfficial
# Provides paginated data for users at /api/v1/users
# Provides single user at /api/v1/users/:id
# Provides current user at /api/v1/users/me
# Only provides whats visible publicly, reference from views/users/show.html.erb

module Api
  module V1
    class UsersController < ApplicationController
      include Pagy::Backend
      before_action :authenticate_user! # omg

      def index
        page = params[:page].to_i
        if page < 1
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        begin
          pagy, users = pagy(
            User.order(:id), # order by id
            items: 20,
            page: page
          )
        rescue Pagy::OverflowError
          render json: {
            error: "Page out of bounds"
          }, status: :not_found
          return
        end

        @users = users.map do |user|
        {
          id: user.id,
          slack_id: user.slack_id,
          display_name: user.display_name,
          bio: user.user_profile&.bio,
          projects_count: user.projects.count,
          devlogs_count: user.devlogs.count,
          votes_count: user.votes.count,
          ships_count: user.projects.joins(:ship_events).distinct.count,
          projects: user.projects.map { |p| { id: p.id, title: p.title, devlogs_count: p.devlogs_count, created_at: p.created_at } },
          coding_time_seconds: user.has_hackatime? ? user.all_time_coding_seconds : 0,
          coding_time_seconds_today: user.has_hackatime? ? user.daily_coding_seconds : 0,
          balance: current_user&.has_badge?(:pocket_watcher) ? (user.has_badge?(:offshore_bank_account) ? "Nice try, but they've covered their tracks a little better than that." : user.balance) : "You need to have a pocket watcher badge to view this.",
          badges: user.badges.map { |b|
            icon = b[:icon].include?(".") ? view_context.image_url(b[:icon]) : b[:icon]
            {
              name: b[:name],
              text: b[:flavor_text],
              icon: icon
            }
          },
          created_at: user.created_at,
          updated_at: user.updated_at,
          avatar: user.avatar,
          custom_css: user.user_profile&.custom_css
        }
      end
        render json: {
          users: @users,
          pagination: {
            page: pagy.page,
            pages: pagy.pages,
            count: pagy.count,
            items: pagy.limit
          }
        }
      end

      def show
        @user = User.find(params[:id])
        render json: {
          id: @user.id,
          slack_id: @user.slack_id,
          display_name: @user.display_name,
          bio: @user.user_profile&.bio,
          projects_count: @user.projects.count,
          devlogs_count: @user.devlogs.count,
          votes_count: @user.votes.count,
          ships_count: @user.projects.joins(:ship_events).distinct.count,
          projects: @user.projects.map { |p| { id: p.id, title: p.title, devlogs_count: p.devlogs_count, created_at: p.created_at } },
          coding_time_seconds: @user.has_hackatime? ? @user.all_time_coding_seconds : 0,
          coding_time_seconds_today: @user.has_hackatime? ? @user.daily_coding_seconds : 0,
          balance: current_user&.has_badge?(:pocket_watcher) ? (@user.has_badge?(:offshore_bank_account) ? "Nice try, but they've covered their tracks a little better than that." : @user.balance) : "You need to have a pocket watcher badge to view this.",
          badges: @user.badges.map { |b|
            icon = b[:icon].include?(".") ? view_context.image_url(b[:icon]) : b[:icon]
            {
              name: b[:name],
              text: b[:flavor_text],
              icon: icon
            }
          },
          created_at: @user.created_at,
          updated_at: @user.updated_at,
          avatar: @user.avatar,
          custom_css: @user.user_profile&.custom_css
        }
      end

      def me
        user = current_user
        render json: {
          id: user.id,
          slack_id: user.slack_id,
          display_name: user.display_name,
          bio: user.user_profile&.bio,
          projects_count: user.projects.count,
          devlogs_count: user.devlogs.count,
          votes_count: user.votes.count,
          ships_count: user.projects.joins(:ship_events).distinct.count,
          projects: user.projects.map { |p| { id: p.id, title: p.title, devlogs_count: p.devlogs_count, created_at: p.created_at } },
          coding_time_seconds: user.has_hackatime? ? user.all_time_coding_seconds : 0,
          coding_time_seconds_today: user.has_hackatime? ? user.daily_coding_seconds : 0,
          balance: user.has_badge?(:pocket_watcher) ? (user.has_badge?(:offshore_bank_account) ? "Nice try, but they've covered their tracks a little better than that." : user.balance) : "You need to have a pocket watcher badge to view this.",
          badges: user.badges.map { |b|
            icon = b[:icon].include?(".") ? view_context.image_url(b[:icon]) : b[:icon]
            {
              name: b[:name],
              text: b[:flavor_text],
              icon: icon
            }
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
