# frozen_string_literal: true

class ShopItemsController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  before_action :require_admin!, except: [ :index ]
  before_action :refresh_verf!, only: :index

  def index
  # Load all shop items from cache with properly preloaded attachments
  all_shop_items = Rails.cache.fetch("all_shop_items_with_variants_v2", expires_in: 10.minutes) do
  ShopItem.with_attached_image
  .includes(image_attachment: { blob: { variant_records: :image_attachment } })
  .order(ticket_cost: :asc)
  .to_a
  end

  # Filter in memory based on user-specific logic
  filtered_items = all_shop_items.dup

  # Filter out black market items unless user has access
  unless current_user&.has_black_market?
  filtered_items.reject! { |item| item.requires_black_market? }
  end

  # Filter out free stickers that have already been ordered by the current user
  # This filtering must happen at runtime, not in cache, since it's user-specific
  if current_user
  ordered_free_sticker_ids = current_user.shop_orders
  .joins(:shop_item)
  .where(shop_items: { type: "ShopItem::FreeStickers" })
                              .pluck(:shop_item_id)
    filtered_items.reject! { |item| item.is_a?(ShopItem::FreeStickers) && ordered_free_sticker_ids.include?(item.id) }
  end

    @shop_items = filtered_items
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

  def refresh_verf!
    return unless current_user&.identity_vault_linked?
    return if current_verification_status == :verified
    current_user&.refresh_identity_vault_data!
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
