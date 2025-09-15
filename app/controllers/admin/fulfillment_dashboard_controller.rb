# frozen_string_literal: true

module Admin
  class FulfillmentDashboardController < ApplicationController
    include Pagy::Backend
    before_action :ensure_authorized_user
    skip_before_action :authenticate_admin!

    def index
      @fulfillment_type = params[:fulfillment_type] || "all"
      @pagy, @orders = pagy(filtered_orders(@fulfillment_type))
      generate_statistics
    end

    private

    def fulfillment_type_filters
      {
        "hq_mail" => "ShopItem::HQMailItem",
        "third_party" => "ShopItem::ThirdPartyPhysical",
        "sinkening" => "ShopItem::SinkeningBalloons",
        "warehouse" => [ "ShopItem::WarehouseItem", "ShopItem::PileOfStickersItem" ]
      }
    end

    def base_fulfillment_scope(include_associations: false)
      scope = ShopOrder.where(aasm_state: [ "pending", "awaiting_periodical_fulfillment" ])
                       .where.not(shop_items: { type: "ShopItem::FreeStickers" })
                       .joins(:shop_item)

      if include_associations
        scope = scope.includes(:user, :shop_item)
                     .order(:awaiting_periodical_fulfillment_at, :created_at)
      end

      scope
    end

    def filtered_orders(fulfillment_type)
      base_scope = base_fulfillment_scope(include_associations: true)

      if fulfillment_type == "all" || !fulfillment_type_filters.key?(fulfillment_type)
        base_scope
      else
        shop_item_types = fulfillment_type_filters[fulfillment_type]
        base_scope.where(shop_items: { type: shop_item_types })
      end
    end

    def generate_statistics
      base_orders = base_fulfillment_scope

      @stats = {}

      fulfillment_type_filters.each do |type, shop_item_types|
        @stats[type.to_sym] = generate_type_stats(base_orders.where(shop_items: { type: shop_item_types }))
      end

      @stats[:all] = generate_type_stats(base_orders)
    end

    def generate_type_stats(scope)
      results = scope.group(:aasm_state)
                     .select(
                       :aasm_state,
                       "COUNT(*) as count",
                       "AVG(EXTRACT(EPOCH FROM (NOW() - shop_orders.created_at))) as avg_hours_since_order",
                       "AVG(EXTRACT(EPOCH FROM (NOW() - shop_orders.awaiting_periodical_fulfillment_at))) as avg_hours_since_fulfillment"
                     )
                     .map { |r| [ r.aasm_state, r ] }.to_h

      pending = results["pending"]
      awaiting = results["awaiting_periodical_fulfillment"]

      {
        pc: pending&.count || 0,
        ac: awaiting&.count || 0,
        aho: pending&.avg_hours_since_order&.to_i || 0,
        ahf: awaiting&.avg_hours_since_fulfillment&.to_i || 0
      }
    end



    def ensure_authorized_user
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end
  end
end
