# frozen_string_literal: true

module Admin
  class ShopCardGrantsController < ApplicationController
    include Pagy::Backend
    before_action :set_shop_card_grant, only: [ :show, :refresh_hcb_data ]

    def scope
      ShopCardGrant.all.includes(:user, :shop_item).order(created_at: :desc)
    end

    def index
      @pagy, @shop_card_grants = pagy(scope)
    end

    def show
      @hcb_data = @shop_card_grant.hcb_data if @shop_card_grant.hcb_grant_hashid
    rescue => e
      flash[:error] = "Error loading HCB data: #{e.message}"
      @hcb_data = nil
    end

    def refresh_hcb_data
      if @shop_card_grant.hcb_grant_hashid
        @shop_card_grant.instance_variable_set(:@hcb_data, nil) # Clear cached data
        @hcb_data = @shop_card_grant.hcb_data
        flash[:success] = "HCB data refreshed"
      else
        flash[:error] = "No HCB grant ID found"
      end
      redirect_to [ :admin, @shop_card_grant ]
    rescue => e
      flash[:error] = "Error refreshing HCB data: #{e.message}"
      redirect_to [ :admin, @shop_card_grant ]
    end

    private

    def set_shop_card_grant
      @shop_card_grant = scope.find(params[:id])
    end
  end
end
