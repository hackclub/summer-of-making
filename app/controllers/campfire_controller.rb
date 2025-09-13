class CampfireController < ApplicationController
  before_action :authenticate_user!, only: [ :index ]
  before_action :build_account_status, only: [ :index ]
  before_action :check_and_mark_tutorial_completion, only: [ :index ]

  def index
    @user = current_user

    if params[:tutorial_completed] == "true" && @user.tutorial_completed?
      @user.update!(has_clicked_completed_tutorial_modal: true)
    end

    if params[:mark_video_seen] == "true" && @user.tutorial_completed?
      @user.update!(tutorial_video_seen: true)
      if request.xhr?
        render json: { success: true }
        return
      else
        redirect_to campfire_path and return
      end
    end

    if params[:reset].present? && @user&.tutorial_progress
      @user.tutorial_progress.reset_step!(params[:reset])

      tutorial = get_tutorials.find { |t| t[:id] == params[:reset] }
      tutorial_path = tutorial&.[](:path) || campfire_path
      redirect_to tutorial_path
    end

    @announcements = get_announcements
    @tutorials = get_tutorials
    @tutorial_progress = get_tutorial_progress

    # Stickerlode
    if Flipper.enabled?(:advent_of_stickers, @user)
      today = Date.current
      first_advent_day = ShopItem::AdventSticker.minimum(:unlock_on)
      @advent_cards = []
      if first_advent_day
        advent_day = (today - first_advent_day).to_i + 1
        dates = advent_day == 1 ? [ today, today + 1, today + 2 ] : [ today - 1, today, today + 1 ]
        preloaded = ShopItem::AdventSticker
          .where(unlock_on: dates)
          .with_attached_image
          .with_attached_silhouette_image
          .index_by(&:unlock_on)

        @advent_cards = if advent_day == 1
          [
            { sticker: preloaded[today], label: "Today", state: :today, date: today },
            { sticker: preloaded[today + 1], label: "Tomorrow", state: :upcoming, date: today + 1 },
            { sticker: preloaded[today + 2], label: (today + 2).strftime("%b %-d"), state: :upcoming, date: today + 2 }
          ]
        else
          [
            { sticker: preloaded[today - 1], label: "Yesterday", state: :past, date: today - 1 },
            { sticker: preloaded[today], label: "Today", state: :today, date: today },
            { sticker: preloaded[today + 1], label: "Tomorrow", state: :upcoming, date: today + 1 }
          ]
        end
      end
    end

    # Hackatime dashboard data
    if @account_status[:hackatime_setup] && @user.user_hackatime_data.present?
      begin
        @hackatime_dashboard = {
        total_time: @user.all_time_coding_seconds,
        today_time: @user.daily_coding_seconds,
        has_time_recorded: @user.all_time_coding_seconds > 0,
          error: false
        }
      rescue => e
        Rails.logger.error("Failed to fetch Hackatime dashboard data: #{e.message}")
        Honeybadger.notify(e)
        @hackatime_dashboard = {
          total_time: 0,
          today_time: 0,
          has_time_recorded: false,
          error: true,
          error_message: "Unable to connect to Hackatime right now"
        }
      end
    end
  end

  def show
  end

  def hackatime_status
    unless current_user
      render json: {
        error: true,
        error_message: "not logged in"
      }, status: :unauthorized and return
    end

    # Build dashboard data if hackatime is set up
    dashboard_data = nil
    if current_user.has_hackatime? && current_user.user_hackatime_data.present?
      begin
        dashboard_data = {
        total_time: current_user.all_time_coding_seconds,
        today_time: current_user.daily_coding_seconds,
        has_time_recorded: current_user.all_time_coding_seconds > 0,
        total_time_formatted: current_user.format_seconds(current_user.all_time_coding_seconds),
        today_time_formatted: current_user.format_seconds(current_user.daily_coding_seconds),
          error: false
        }
      rescue => e
        Rails.logger.error("Failed to fetch Hackatime status data: #{e.message}")
        Honeybadger.notify(e)
        dashboard_data = {
          total_time: 0,
          today_time: 0,
          has_time_recorded: false,
          total_time_formatted: "0h 0m",
          today_time_formatted: "0h 0m",
          error: true,
          error_message: "Unable to connect to Hackatime right now"
        }
      end
    end

    render json: {
      hackatime_linked: current_user.has_hackatime_account?,
      hackatime_setup: current_user.has_hackatime?,
      hackatime_projects: current_user.hackatime_projects.any?,
      dashboard: dashboard_data
    }
  end

  private

  def check_and_mark_tutorial_completion
    return if current_user.tutorial_completed?

    if @account_status[:hackatime_setup] && !current_user.tutorial_progress.step_completed?("hackatime_connected")
      current_user.tutorial_progress.complete_step!("hackatime_connected")
    end

    if current_user.identity_vault_id.present? && current_verification_status != :ineligible && !current_user.tutorial_progress.step_completed?("identity_verified")
      current_user.tutorial_progress.complete_step!("identity_verified")
    end

    if current_user.shop_orders.joins(:shop_item).where(shop_items: { type: "ShopItem::FreeStickers" }).exists? && !current_user.tutorial_progress.step_completed?("free_stickers_ordered")
      current_user.tutorial_progress.complete_step!("free_stickers_ordered")
    end

    if @account_status[:hackatime_setup] && current_user.tutorial_progress.step_completed?("hackatime_connected") && current_user.tutorial_progress.step_completed?("identity_verified") && current_user.tutorial_progress.step_completed?("free_stickers_ordered")
      current_user.tutorial_progress.completed_at = Time.current
      current_user.tutorial_progress.save!
    end
  end

  def build_account_status
    @account_status = {
      hackatime_linked: current_user.has_hackatime_account?,
      hackatime_setup: current_user.has_hackatime?,
      hackatime_projects: current_user.hackatime_projects.any?
    }
  end

  def get_announcements
    announcements = []

    announcements
  end

  def get_tutorials
    tutorials = [
      {
        id: "campfire",
        title: "This is the campfire!",
        description: "This is where you'll see announcements, tutorials, account status and anything that needs your attention. Think of it as your notification/action center!",
        path: "/campfire",
        order: 1,
        completed: tutorial_completed?("campfire")
      },
      {
        id: "explore",
        title: "Explore Projects",
        description: "This is like a social feed where you'll see devlogs – mini blogs from other hackers sharing what they're working on. Follow other hackers to see their projects! Check the Following tab for projects you've hit follow on, and browse the Gallery for all the cool stuff hackers have built.",
        path: "/explore",
        order: 2,
        completed: tutorial_completed?("explore")
      },
      {
        id: "my_projects",
        title: "Visit My Projects",
        description: "This is where you can see all your projects, create new ones, and edit or delete them. Go crazy!",
        path: "/my_projects",
        order: 3,
        completed: tutorial_completed?("my_projects")
      },
      {
        id: "vote",
        title: "Check out the Arena",
        description: "This is where you'll vote on other hackers' projects and where your own projects will get voted on too. The better your projects perform, the more shells you'll earn. Go ahead – pick left, right, or maybe call it a tie?",
        path: "/votes/new",
        order: 4,
        completed: tutorial_completed?("vote")
      },
      {
        id: "shop",
        title: "Visit the Shop",
        description: "This is where you can buy stuff with your shells. We'll be releasing new items throughout the summer, so check back often!",
        path: "/shop",
        order: 5,
        completed: tutorial_completed?("shop")
      }
    ]

    # Sort tutorials by order
    tutorials.sort_by { |t| t[:order] }
  end

  def get_next_tutorial
    tutorials = get_tutorials
    next_tutorial = tutorials.find { |t| !t[:completed] }
    next_tutorial
  end

  def get_tutorial_progress
    tutorials = get_tutorials
    completed_count = tutorials.count { |t| t[:completed] }
    total_count = tutorials.length

    {
      completed: completed_count,
      total: total_count,
      percentage: (completed_count.to_f / total_count * 100).round,
      next_tutorial: get_next_tutorial
    }
  end

  def tutorial_completed?(step_name)
    return false unless @user&.tutorial_progress

    @user.tutorial_progress.step_completed?(step_name)
  end
end
