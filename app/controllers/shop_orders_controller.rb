class ShopOrdersController < ApplicationController
  before_action :set_shop_order, only: [ :show ]
  before_action :set_shop_item, only: [ :new, :create ]
  def index
    @orders = current_user.shop_orders.includes(:shop_item).order(created_at: :desc)
  end

  def show
  end

  def new
    @order = ShopOrder.new

    # Special handling for free stickers - collect address first if user doesn't have IDV addresses
    if @item.is_a?(ShopItem::FreeStickers) && !current_user.has_idv_addresses?
      return_url = order_shop_item_url(@item)
      sneaky_params = { address_return_to: return_url }

      redirect_url = IdentityVaultService.build_address_creation_url(sneaky_params)

      redirect_to redirect_url, allow_other_host: true
      return
    end

    # Check if user can afford this item
    if @item.ticket_cost.present? && @item.ticket_cost > 0 && current_user.balance < @item.ticket_cost
      redirect_to shop_path, alert: "You don't have enough tickets to purchase #{@item.name}. You need #{@item.ticket_cost - current_user.balance} more tickets."
      nil
    end
  end

  def create
    @order = current_user.shop_orders.build(shop_order_params)
    @order.shop_item = @item
    @order.frozen_item_price = @item.ticket_cost

    # Use selected address from IDV data if provided, fallback to user's address
    if params[:shipping_address_id].present?
      # Find the selected address from IDV data
      idv_data = current_user.fetch_idv
      selected_address = idv_data.dig(:identity, :addresses)&.find { |addr| addr[:id].to_s == params[:shipping_address_id] }
      @order.frozen_address = selected_address if selected_address
    elsif current_user.respond_to?(:address_hash)
      @order.frozen_address = current_user.address_hash
    end

    if @order.save
      redirect_to shop_order_path(@order), notice: "Order placed successfully! We'll review and process your order soon."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_shop_order
    @order = current_user.shop_orders.find(params[:id])
  end

  def set_shop_item
    scope = ShopItem.all
    scope = scope.not_black_market unless current_user.has_black_market?
    @item = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shop_path, alert: "Item not found."
  end

  def shop_order_params
    params.permit(:quantity)
  end
end
