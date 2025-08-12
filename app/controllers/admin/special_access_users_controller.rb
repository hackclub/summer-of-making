module Admin
  class SpecialAccessUsersController < ApplicationController
    def index
      @users = User.all

      # Apply filters based on params
      if params[:admin] == "true"
        @users = @users.where(is_admin: true)
      end

      if params[:fraud_team] == "true"
        @users = @users.where(fraud_team_member: true)
      end

      if params[:ship_certifier] == "true"
        @users = @users.where("permissions::jsonb ? 'shipcert'")
      end

      if params[:black_market] == "true"
        @users = @users.where(has_black_market: true)
      end

      # If no filters are applied, show only users with special access
      if params.slice(:admin, :fraud_team, :ship_certifier).values.none? { |v| v == "true" }
        @users = @users.where(
          "is_admin = ? OR fraud_team_member = ? OR ysws_verified = ?",
          true, true, true
        )
      end

      @users = @users.order(:display_name)

      # Get recent activities for these users (limit to prevent performance issues)
      @recent_activities = PublicActivity::Activity.where(owner: @users)
        .order(created_at: :desc)
        .limit(50)
        .includes(:owner, :trackable)

      # Get top 25 most recent actions for audit log
      @audit_log_activities = PublicActivity::Activity.where(owner: @users)
        .where.not(key: [ "create", "update" ]) # Exclude basic CRUD to focus on important actions
        .order(created_at: :desc)
        .limit(25)
        .includes(:owner, :trackable)
    end
  end
end
