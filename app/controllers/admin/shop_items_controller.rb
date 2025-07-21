# frozen_string_literal: true

module Admin
  class ShopItemsController < ApplicationController
    include Pagy::Backend
    before_action :set_shop_item, except: [ :index, :new, :create ]

    def index
      @pagy, @shop_items = pagy(ShopItem.all.with_attached_image.order(created_at: :desc))
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
      params.require(:shop_item).permit(:type, :name, :description, :under_the_fold_description, :internal_description,
                                        :ticket_cost, :usd_cost, :hacker_score, :max_qty,
                                        :requires_black_market, :show_in_carousel, :one_per_person_ever, :enabled,
                                        :hcb_merchant_lock, :hcb_category_lock, :hcb_keyword_lock, :hcb_preauthorization_instructions,
                                        :agh_contents, :image, :limited, :stock, :site_action,
                                        *ShopItem.region_columns)
    end
  end
end
