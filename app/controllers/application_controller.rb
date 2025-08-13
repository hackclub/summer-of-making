# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include PublicActivity::StoreController
  include Pundit::Authorization

  before_action :set_paper_trail_whodunnit

  # before_action :try_rack_mini_profiler_enable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern
  before_action do
    Rails.logger.info ">>> Session[:user_id] = #{session[:user_id]}"
    Rails.logger.info ">>> Current user ID: #{current_user&.id}"
    Rails.logger.info ">>> Request IP: #{request.remote_ip}, User-Agent: #{request.user_agent}"
  end

  before_action :authenticate_user!
  before_action :check_if_banned
  before_action :fetch_hackatime_data_if_needed
  before_action :compute_todo_flags
  after_action :track_page_view

  helper_method :current_user, :user_signed_in?, :current_verification_status, :current_impersonator, :impersonating?

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_impersonator
    @current_impersonator ||= User.find_by(id: session[:impersonator_user_id]) if session[:impersonator_user_id]
  end

  def current_verification_status
    @current_verification_status ||= current_user&.verification_status
  end

  def user_signed_in?
    !!current_user
  end

  def impersonating?
    !!current_impersonator
  end

  def authenticate_user!
    redirect_to root_path, alert: "Please sign in to access this page" unless user_signed_in?
  end

  def check_if_banned
    return unless user_signed_in?
    return false if current_user.is_banned?.nil?
    return unless current_user.is_banned?

    unless controller_name == "campfire"
      redirect_to campfire_path, alert: "You can not access this!"
    end
  end

  def require_admin!
    redirect_to "/" unless current_user && current_user.is_admin?
  end

  def require_fraud_team!
    redirect_to "/" unless current_user && (current_user.fraud_team_member? || current_user.is_admin?)
  end

  def user_for_paper_trail = current_impersonator&.id || current_user&.id
  def info_for_paper_trail = { extra_data: { impersonating: impersonating?, pretending_to_be: current_impersonator && current_user }.compact_blank }

  private

  def try_rack_mini_profiler_enable
    if current_user && current_user.is_admin?
      Rack::MiniProfiler.authorize_request
    end
  end

  def fetch_hackatime_data_if_needed
    return if !user_signed_in? || current_user.hackatime_projects.any?

    Rails.cache.fetch("hackatime_fetch_#{current_user.id}", expires_in: 5.seconds) do
      current_user.refresh_hackatime_data_now
    end
  end

  # precompute flags used by tutorial/_todo_modal to avoid pervew queries on every page and avoid hammering the db :heavysob:
  # the db is like young kartikey and the hammering was from my parents :pf:
  def compute_todo_flags
    return unless user_signed_in?

    @todo_flags = Rails.cache.fetch("todo_flags/#{current_user.id}", expires_in: 45.seconds) do
      has_projects = if current_user.association(:projects).loaded?
        current_user.projects.any?
      else
        current_user.projects.exists?
      end

      has_devlogs = if current_user.association(:devlogs).loaded?
        current_user.devlogs.any?
      else
        current_user.devlogs.exists?
      end

      has_ship_events = if current_user.association(:projects).loaded?
        current_user.ship_events.loaded? ? current_user.ship_events.any? : current_user.ship_events.exists?
      else
        current_user.ship_events.exists?
      end

      has_votes = if current_user.association(:votes).loaded?
        current_user.votes.any?
      else
        current_user.votes.exists?
      end

      has_non_free_order = begin
        orders_assoc = current_user.association(:shop_orders)
        if orders_assoc.loaded?
          current_user.shop_orders.any? { |o| o.shop_item && o.shop_item.type != "ShopItem::FreeStickers" }
        else
          current_user.shop_orders.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" }).exists?
        end
      end

      {
        has_projects: has_projects,
        has_devlogs: has_devlogs,
        has_ship_events: has_ship_events,
        has_votes: has_votes,
        has_non_free_order: has_non_free_order
      }
    end
  end

  def track_page_view
    ahoy.track "$view", {
      controller: params[:controller],
      action: params[:action],
      user_id: current_user&.id
    }
  end
end
