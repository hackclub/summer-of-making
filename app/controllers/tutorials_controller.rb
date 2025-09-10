# frozen_string_literal: true

class TutorialsController < ApplicationController
  before_action :authenticate_user!

  def todo_modal
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

    render partial: "tutorial/todo_modal", layout: false
  end
end
