# frozen_string_literal: true

class ShopItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!, except: [ :index ]

  def index
    if current_user.ysws_verified?
      scope = ShopItem.where.not(type: "ShopItem::FreeStickers")
      scope = scope.not_black_market unless current_user.has_black_market?
      @shop_items = scope.order(ticket_cost: :asc)
    else
      scope = ShopItem.where(type: "ShopItem::FreeStickers")
      scope = scope.not_black_market unless current_user.has_black_market?
      @shop_items = scope.order(ticket_cost: :asc)
    end
    @shop_item_types = available_shop_item_types
  end

  def new
    @shop_item = ShopItem.new
    @shop_item_types = available_shop_item_types
  end

  def create
    @shop_item = ShopItem.new(shop_item_params)
    Rails.logger.debug @shop_item

    if @shop_item.save
      redirect_to shop_items_path, notice: "Shop item was successfully created."
    else
      @shop_item_types = available_shop_item_types
      render :new, status: :unprocessable_entity
    end
  end

  def update
    ShopItem.find(params[:id]).update!(shop_item_params)
  end

  private

  def require_admin!
    return if current_user&.is_admin?

    redirect_to root_path, alert: "You don't have permission to access this yet!"
  end

  def available_shop_item_types
    # Explicitly require all shop item type files
    Rails.root.glob("app/models/shop_item/*.rb").each { |file| require_dependency file }

    # Now get all descendants
    ShopItem.descendants.map { |type| [ type.name.demodulize.underscore.humanize, type.name ] }
  end

  def shop_item_params
    params.expect(
      shop_item: %i[type name description internal_description
                    actual_irl_fr_cost cost hacker_score
                    requires_black_market hcb_merchant_lock
                    hcb_category_lock hcb_keyword_lock agh_contents
                    image]
    )
  end
end
