class ShopOrdersController < ApplicationController
  before_action :set_shop_order, only: [ :show ]
  before_action :set_shop_item, only: [ :new, :create ]
  def index
  end

  def show
  end

  def new
  end

  def create
  end

  private

  def set_shop_order
    @order = current_user.shop_orders.find(params[:id])
  end

  def set_shop_item
    scope = ShopItem.all
    scope = scope.not_black_market unless current_user.has_black_market?
    @item = scope.find(params[:id])
  end
end
