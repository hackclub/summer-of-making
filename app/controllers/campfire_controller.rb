class CampfireController < ApplicationController
  before_action :authenticate_user!, only: [ :index ]
  before_action :build_account_status, only: [ :index ]
  before_action :check_and_mark_tutorial_completion, only: [ :index ]

  def index
    @user = current_user

    if params[:tutorial_completed] == "true" && @user.tutorial_progress.completed?
      @user.update!(has_clicked_completed_tutorial_modal: true)
    end

    if params[:mark_video_seen] == "true" && @user.tutorial_progress.completed?
      @user.update!(tutorial_video_seen: true)
      redirect_to campfire_path and return
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
  end

  def show
  end

  def hackatime_status
    render json: {
      hackatime_linked: current_user.has_hackatime_account?,
      hackatime_setup: current_user.has_hackatime?,
      hackatime_projects: current_user.has_hackatime_projects?
    }
  end

  private

  def check_and_mark_tutorial_completion
    return if current_user.tutorial_progress.completed?

    if @account_status[:hackatime_setup] && !current_user.tutorial_progress.step_completed?("hackatime_connected")
      current_user.tutorial_progress.complete_step!("hackatime_connected")
    end

    if current_user.identity_vault_id.present? && current_user.verification_status != :ineligible && !current_user.tutorial_progress.step_completed?("identity_verified")
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
      hackatime_projects: current_user.has_hackatime_projects?
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
        description: "This is where you can buy stuff with your shells. You'll earn shells by working on your projects and shipping them! PS: Take a look at the shop items – they're all made by hackers for hackers. (go ahead, get greedy!)",
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
