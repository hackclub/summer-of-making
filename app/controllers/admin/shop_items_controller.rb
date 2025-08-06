# frozen_string_literal: true

module Admin
  class ShopItemsController < ApplicationController
    include Pagy::Backend
    before_action :set_shop_item, except: [ :index, :new, :create ]

    def index
      @shop_items = filter_and_search_shop_items
      @pagy, @shop_items = pagy(@shop_items)
      @available_types = available_shop_item_types
    end

    def show
      @shop_orders = @shop_item.shop_orders.includes(:user).order(created_at: :desc).limit(20)
    end

    def new
      @shop_item = ShopItem.new
      @shop_item_types = available_shop_item_types
    end

    def create
      @shop_item = ShopItem.new(shop_item_params)

      if @shop_item.save
        flash[:success] = "Shop item was successfully created."
        redirect_to [ :admin, @shop_item.becomes(ShopItem) ]
      else
        @shop_item_types = available_shop_item_types
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @shop_item_types = available_shop_item_types
    end

    def update
      if @shop_item.update(shop_item_params)
        flash[:success] = "Shop item was successfully updated."
        redirect_to [ :admin, @shop_item.becomes(ShopItem) ]
      else
        @shop_item_types = available_shop_item_types
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shop_item.destroy!
      flash[:success] = "BALEETED!"
      redirect_to admin_shop_items_path
    end

    private

    def filter_and_search_shop_items
      items = ShopItem.all.with_attached_image

      # Text search across name, description, and internal_description
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        items = items.where(
          "name ILIKE ? OR description ILIKE ? OR internal_description ILIKE ?",
          search_term, search_term, search_term
        )
      end

      # Filter by type
      if params[:type].present? && params[:type] != "all"
        items = items.where(type: params[:type])
      end

      # Filter by enabled status
      case params[:enabled]
      when "enabled"
        items = items.enabled
      when "disabled"
        items = items.where(enabled: false)
      end

      # Filter by black market
      case params[:black_market]
      when "yes"
        items = items.black_market
      when "no"
        items = items.not_black_market
      end

      # Filter by carousel
      case params[:carousel]
      when "yes"
        items = items.shown_in_carousel
      when "no"
        items = items.where(show_in_carousel: [ false, nil ])
      end

      # Filter by limited stock
      case params[:limited]
      when "limited"
        items = items.where(limited: true)
      when "unlimited"
        items = items.where(limited: [ false, nil ])
      end

      # Filter by enabled regions
      column_map = {
        "us" => :enabled_us,
        "eu" => :enabled_eu,
        "in" => :enabled_in,
        "ca" => :enabled_ca,
        "au" => :enabled_au,
        "xx" => :enabled_xx
      }
      if params[:enabled_region].present? && params[:enabled_region] != "all"
        region = params[:enabled_region]
        if column_map.key?(region)
          items = items.where(column_map[region] => true)
        end
      end

      # Sorting
      case params[:sort]
      when "name_asc"
        items = items.order(:name)
      when "name_desc"
        items = items.order(name: :desc)
      when "cost_asc"
        items = items.order(:ticket_cost)
      when "cost_desc"
        items = items.order(ticket_cost: :desc)
      when "created_asc"
        items = items.order(:created_at)
      when "type_asc"
        items = items.order(:type)
      when "type_desc"
        items = items.order(type: :desc)
      else
        items = items.order(created_at: :desc)
      end

      items
    end

    def set_shop_item
      @shop_item = ShopItem.find(params[:id])
    end

    def available_shop_item_types
      # Explicitly require all shop item type files
      Rails.root.glob("app/models/shop_item/*.rb").each { |file| require_dependency file }

      # Now get all descendants
      ShopItem.descendants.map { |type| [ type.name.demodulize.underscore.humanize, type.name ] }
    end

    def shop_item_params
      permitted_params = params.require(:shop_item).permit(:type, :name, :description, :under_the_fold_description, :internal_description,
                                                            :ticket_cost, :usd_cost, :hacker_score, :max_qty,
                                                            :requires_black_market, :show_in_carousel, :one_per_person_ever, :enabled,
                                                            :hcb_merchant_lock, :hcb_category_lock, :hcb_keyword_lock, :hcb_preauthorization_instructions,
                                                            :agh_contents, :image, :limited, :stock, :site_action,
                                                            *ShopItem.region_columns)

      # Parse agh_contents JSON string if present
      if permitted_params[:agh_contents].present? && permitted_params[:agh_contents].is_a?(String)
        begin
          permitted_params[:agh_contents] = JSON.parse(permitted_params[:agh_contents])
        rescue JSON::ParserError
          # Leave as string if JSON is invalid - let model validation handle it
        end
      end

      permitted_params
    end
  end
end
