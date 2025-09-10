# frozen_string_literal: true

module Admin
  class FulfillmentDashboardController < ApplicationController
    include Pagy::Backend
    before_action :ensure_authorized_user
    skip_before_action :authenticate_admin!

    def index
      @t = params[:fulfillment_type] || "all"
      @p, @o = pagy(f(@t))
      g
    end

    private

    def f(t)
      s = ShopOrder.includes(:user, :shop_item)
                   .where(aasm_state: [ "pending", "awaiting_periodical_fulfillment" ])
                   .where.not(shop_items: { type: "ShopItem::FreeStickers" })
                   .order(:awaiting_periodical_fulfillment_at, :created_at)

      case t
      when "hq_mail"
        s.joins(:shop_item).where(shop_items: { type: "ShopItem::HQMailItem" })
      when "third_party"
        s.joins(:shop_item).where(shop_items: { type: "ShopItem::ThirdPartyPhysical" })
      when "sinkening"
        s.joins(:shop_item).where(shop_items: { type: "ShopItem::SinkeningBalloons" })
      when "warehouse"
        s.joins(:shop_item).where(shop_items: { type: [ "ShopItem::WarehouseItem", "ShopItem::PileOfStickersItem" ] })
      else # "all"
        s
      end
    end

    def g
      b = ShopOrder.joins(:shop_item).where(aasm_state: [ "pending", "awaiting_periodical_fulfillment" ]).where.not(shop_items: { type: "ShopItem::FreeStickers" })

      @s = {}

      @s[:hq_mail] = gt(b.where(shop_items: { type: "ShopItem::HQMailItem" }))
      @s[:third_party] = gt(b.where(shop_items: { type: "ShopItem::ThirdPartyPhysical" }))
      @s[:sinkening] = gt(b.where(shop_items: { type: "ShopItem::SinkeningBalloons" }))
      @s[:warehouse] = gt(b.where(shop_items: { type: [ "ShopItem::WarehouseItem", "ShopItem::PileOfStickersItem" ] }))

      @s[:all] = gt(b)
    end

    def gt(s)
      p = s.where(aasm_state: "pending")
      a = s.where(aasm_state: "awaiting_periodical_fulfillment")

      {
        pc: p.count,
        ac: a.count,
        aho: c(p, :created_at),
        ahf: c(a, :awaiting_periodical_fulfillment_at)
      }
    end

    def c(o, f)
      return 0 if o.empty?

      n = Time.current
      t = o.sum { |r| n - r.send(f) }
      (t / o.count).to_i
    end

    def ensure_authorized_user
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end

    def d(s)
      return "--:--:--" unless s
      h = s / 3600
      m = (s % 3600) / 60
      sec = s % 60
      sprintf("%02d:%02d:%02d", h, m, sec)
    end
    helper_method :d
  end
end
