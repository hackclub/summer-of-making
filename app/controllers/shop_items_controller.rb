# frozen_string_literal: true

require "set"

class ShopItemsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :black_market ]
  before_action :require_admin!, except: [ :index, :black_market ]
  before_action :refresh_verf!, only: [ :index, :black_market ]
  prepend_before_action do
    @regionalization_enabled = true
  end

  def index
  @selected_region = @regionalization_enabled ? determine_user_region : nil
    @region_auto_detected = @regionalization_enabled && session[:region_auto_detected]

  # Load all shop items from cache with properly preloaded attachments
  all_shop_items = Rails.cache.fetch("all_shop_items_with_variants_v2", expires_in: 10.minutes) do
  ShopItem.enabled.with_attached_image.not_black_market
  .includes(image_attachment: { blob: { variant_records: :image_attachment } })
  .order(ticket_cost: :asc)
            .to_a
    end

    # Filter in memory
    filtered_items = all_shop_items.dup

  # Filter by region availability (include XX items in all regions) - only if regionalization is enabled
  if @regionalization_enabled && @selected_region
      filtered_items.select! { |item| item.enabled_in_region?(@selected_region) || item.enabled_in_region?("XX") }
  end

  # Filter out free stickers that have already been ordered by the current user
  if current_user
  ordered_free_sticker_ids = current_user.shop_orders
  .joins(:shop_item)
  .where(shop_items: { type: "ShopItem::FreeStickers" })
                             .pluck(:shop_item_id)
    filtered_items.reject! { |item| ordered_free_sticker_ids.include?(item.id) }
  end

    visible_item_ids = filtered_items.map(&:id)

    @ordered_quantity_by_item_id = if visible_item_ids.any?
      ShopOrder.worth_counting.where(shop_item_id: visible_item_ids).group(:shop_item_id).sum(:quantity)
    else
      {}
    end

    if current_user
      # load them already to avoid database queries
      current_user.user_badges.load
      current_user.payouts.load
      @user_badge_keys = current_user.user_badges.map { |ub| ub.badge_key.to_sym }.to_set

      @ordered_once_item_ids = current_user.shop_orders
                                         .worth_counting
                                         .where(shop_item_id: visible_item_ids)
                                         .group(:shop_item_id)
                                         .pluck(:shop_item_id)
                                         .to_set

      # for some reason we're doing current_user.balance on every item
      @current_balance = current_user.balance
    else
      @ordered_once_item_ids = Set.new
      @current_balance = 0
    end

    # Separate badge items from regular items
    @badge_items = filtered_items.select { |item| item.is_a?(ShopItem::BadgeItem) }
    @regular_items = filtered_items.reject { |item| item.is_a?(ShopItem::BadgeItem) }

    # Keep original @shop_items for compatibility with any existing logic
    @shop_items = filtered_items

    # Prepare optimized item data and verification status for views
    if current_user
      @current_verification_status = current_verification_status
      @current_user_ysws_verified = current_user.ysws_verified?
    end

    # Pre-compute item data for optimized rendering
    prepare_item_data_for(@regular_items)
    prepare_item_data_for(@badge_items)
  end

  def black_market
    return redirect_to shop_path unless current_user&.has_black_market? || current_user&.is_admin?

    @selected_region = @regionalization_enabled ? determine_user_region : nil
    @region_auto_detected = @regionalization_enabled && session[:region_auto_detected]

    all_shop_items = Rails.cache.fetch("all_black_market_shop_items_with_variants", expires_in: 2.minutes) do
      ShopItem.enabled.with_attached_image.black_market
        .includes(image_attachment: { blob: { variant_records: :image_attachment } })
        .order(ticket_cost: :asc)
        .to_a
    end

    filtered_items = all_shop_items.dup

    if @regionalization_enabled && @selected_region
      filtered_items.select! { |item| item.enabled_in_region?(@selected_region) || item.enabled_in_region?("XX") }
    end

    visible_item_ids = filtered_items.map(&:id)

    @ordered_quantity_by_item_id = if visible_item_ids.any?
      ShopOrder.worth_counting.where(shop_item_id: visible_item_ids).group(:shop_item_id).sum(:quantity)
    else
      {}
    end

    if current_user
      current_user.user_badges.load
      current_user.payouts.load
      @user_badge_keys = current_user.user_badges.map { |ub| ub.badge_key.to_sym }.to_set

      @ordered_once_item_ids = current_user.shop_orders
                                         .worth_counting
                                         .where(shop_item_id: visible_item_ids)
                                         .group(:shop_item_id)
                                         .pluck(:shop_item_id)
                                         .to_set

      @current_balance = current_user.balance
    else
      @ordered_once_item_ids = Set.new
      @current_balance = 0
    end

    @shop_items = filtered_items
    render layout: "black_market"
  end

  private

  def determine_user_region
    # URL parameter takes precedence (manual override)
    if params[:region].present? && Shop::Regionalizable::REGION_CODES.include?(params[:region].upcase)
      session[:selected_region] = params[:region].upcase
      session[:region_auto_detected] = false # Clear auto-detection flag
      return params[:region].upcase
    end

    # Check if user has previously selected a region
    return session[:selected_region] if session[:selected_region].present?

    # Try to auto-detect from IDV primary address
    if current_user&.identity_vault_linked?
      begin
        idv_data = current_user.fetch_idv
        addresses = idv_data.dig(:identity, :addresses) || []
        primary_address = addresses.find { |addr| addr[:primary] } || addresses.first

        if primary_address && primary_address[:country]
          region = Shop::Regionalizable.country_to_region(primary_address[:country])
          session[:selected_region] = region
          session[:region_auto_detected] = true # Mark as auto-detected
          return region
        end
      rescue => e
        Rails.logger.warn "Failed to fetch IDV data for region detection: #{e.message}"
      end
    end

    # Default to US if no region detected
    session[:selected_region] = "US"
    session[:region_auto_detected] = false
    "US"
  end

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

  def refresh_verf!
    return unless current_user&.identity_vault_linked?
    return if current_verification_status == :verified
    current_user&.refresh_identity_vault_data!
  end

  private

  def prepare_item_data_for(items)
    items.each do |item|
      regional_price = (@regionalization_enabled && @selected_region) ? item.price_for_region(@selected_region) : item.ticket_cost
      remaining = (item.limited? && item.stock.present?) ? (item.stock - (@ordered_quantity_by_item_id[item.id].to_i)) : nil
      out_of_stock = item.limited? && remaining && remaining <= 0
      already_ordered = item.one_per_person_ever? && @ordered_once_item_ids&.include?(item.id)

      item.define_singleton_method(:item_data) do
        {
          regional_price: regional_price,
          remaining_stock: remaining,
          out_of_stock: out_of_stock,
          already_ordered: already_ordered
        }
      end
    end
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
