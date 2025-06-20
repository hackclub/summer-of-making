class ShopOrdersController < ApplicationController
  before_action :set_shop_order, only: [ :show ]
  before_action :set_shop_item, only: [ :new, :create ]
  before_action :check_freeze, except: [ :index, :show ]
  def index
    @orders = current_user.shop_orders.includes(:shop_item).order(created_at: :desc)
  end

  def show
  end

  def new
    @order = ShopOrder.new
    @selected_region = determine_user_region
    @regional_price = @item.price_for_region(@selected_region)

    # Check if item is available in user's region
    unless @item.enabled_in_region?(@selected_region)
      redirect_to shop_path, alert: "#{@item.name} is not available in your region (#{Shop::Regionalizable.region_name(@selected_region)})."
      return
    end

    # Special handling for free stickers - require IDV linking through OAuth
    if @item.is_a?(ShopItem::FreeStickers) && current_user.identity_vault_id.blank?
      redirect_to current_user.identity_vault_oauth_link(identity_vault_callback_url), allow_other_host: true
      return
    end

    # Check if user can afford this item at regional price
    if @regional_price.present? && @regional_price > 0 && current_user.balance < @regional_price
      redirect_to shop_path, alert: "You don't have enough tickets to purchase #{@item.name}. You need #{@regional_price - current_user.balance} more tickets."
      nil
    end
  end

  def create
    @order = current_user.shop_orders.build(shop_order_params)
    @order.shop_item = @item
    @selected_region = determine_user_region
    @regional_price = @item.price_for_region(@selected_region)
    @order.frozen_item_price = @regional_price

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
      if @item.is_a? ShopItem::FreeStickers
        ahoy.track "tutorial_step_free_stickers_ordered", user_id: current_user.id, order_id: @order.id
        flash[:success] = "We'll send your stickers out when your verification is approved!"
        redirect_to campfire_path
      else
        redirect_to shop_order_path(@order), notice: "Order placed successfully!"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def determine_user_region
    return params[:region] if params[:region].present? && Shop::Regionalizable::REGION_CODES.include?(params[:region].upcase)
    return session[:selected_region] if session[:selected_region].present?

    if current_user&.identity_vault_linked?
      addresses = current_user.addresses || []
      primary_address = addresses.find { |addr| addr["primary"] } || addresses.first
      if primary_address && primary_address["country"]
        region = Shop::Regionalizable.country_to_region(primary_address["country"])
        session[:selected_region] = region
        return region
      end
    end

    "US"
  end

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

  def check_freeze
    if current_user&.freeze_shop_activity?
      redirect_to shop_path, alert: "You can't make purchases right now."
    end
  end

  def shop_order_params
    params.permit(:quantity)
  end
end
