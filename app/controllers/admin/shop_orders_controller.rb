# frozen_string_literal: true

module Admin
  class ShopOrdersController < ApplicationController
    include Pagy::Backend
    before_action :ensure_authorized_user
    before_action :set_shop_order, except: [ :index, :pending, :awaiting_fulfillment ]
    skip_before_action :authenticate_admin!

    def scope
      ShopOrder.all.includes(:user, :shop_item)
    end

    def filtered_scope
      base = scope

      unless params[:show_free_stickers] == "true"
        base = base.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" })
      end

      if params[:user_search].present?
        query = "%#{params[:user_search]}%"
        base = base.joins(:user).where(
          "users.display_name ILIKE ? OR users.email ILIKE ? OR users.slack_id ILIKE ?",
          query, query, query
        )
      end

      if params[:shop_item_id].present?
        base = base.where(shop_item_id: params[:shop_item_id])
      end

      if params[:status].present?
        base = base.where(aasm_state: params[:status])
      end

      if params[:date_from].present?
        base = base.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
      end

      if params[:date_to].present?
        base = base.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
      end

      if params[:country].present?
        base = base.where("frozen_address->>'country' ILIKE ?", "%#{params[:country]}%")
      end

      case params[:sort]
      when "id_asc"
        base = base.order(id: :asc)
      when "id_desc"
        base = base.order(id: :desc)
      when "shells_asc"
        base = base.order(frozen_item_price: :asc)
      when "shells_desc"
        base = base.order(frozen_item_price: :desc)
      when "created_at_asc"
        base = base.order(created_at: :asc)
      when "created_at_desc"
        base = base.order(created_at: :desc)
      else
        base = base.order(created_at: :desc)
      end

      base
    rescue Date::Error
      base
    end

    def index
      if params[:goob] == "true"
        @grouped_orders = group_all(filtered_scope)
        @pagy = nil
      else
        @pagy, @shop_orders = pagy(filtered_scope)
      end
      get_stats
    end

    def pending
      @pagy, @shop_orders = pagy(filtered_scope.pending)
      get_stats
      render :index, locals: { title: "pending " }
    end

    def awaiting_fulfillment
      scope = filtered_scope.manually_fulfilled.awaiting_periodical_fulfillment
      if params[:goob] == "true"
        @grouped_orders = group_all(scope)
        @pagy = nil
      else
        @pagy, @shop_orders = pagy(scope)
      end
      get_stats
      render :index, locals: { title: "fulfillment queue – " }
    end

    def show
      @activities = @shop_order.activities.order(created_at: :desc).includes(:owner)
    end

    def internal_notes
      @shop_order.update!(internal_notes: params[:internal_notes])
      @shop_order.create_activity("edit_internal_notes", params: { note: params[:internal_notes] })
      render :internal_notes, layout: false
    end

    def approve
      @shop_order.approve!
      @shop_order.create_activity("approve")
      flash[:success] = "awesome!"
      redirect_to pending_admin_shop_orders_path
    end

    def reject
      rejection_reason = params[:rejection_reason]
      unless rejection_reason
        redirect_to @shop_order, notice: "you need to provide a rejection reason!"
        return
      end

      if @shop_order.aasm_state == "on_hold"
        @shop_order.take_off_hold!
      end

      @shop_order.mark_rejected!(rejection_reason)
      @shop_order.create_activity("reject", parameters: { rejection_reason: })
      flash[:success] = "rejected with extreme prejudice..."
      redirect_to [ :admin, @shop_order ]
    end

    def place_on_hold
      @shop_order.place_on_hold!
      @shop_order.create_activity("hold")
      flash[:success] = "holding..."
      redirect_to [ :admin, @shop_order ]
    end

    def take_off_hold
      @shop_order.take_off_hold!
      @shop_order.create_activity("unhold")
      flash[:success] = "fire when ready!"
      redirect_to [ :admin, @shop_order ]
    end

    def mark_fulfilled
      redirect_to @shop_order, notice: "huh!?" unless @shop_order.shop_item.manually_fulfilled?
      external_ref = params[:external_ref]
      fulfillment_cost = params[:fulfillment_cost].presence
      redirect_to @shop_order, notice: "you need to provide a reference!" unless external_ref
      @shop_order.mark_fulfilled!(external_ref, fulfillment_cost, current_user.display_name)
      @shop_order.create_activity("mark_fulfilled", parameters: { external_ref: })
      flash[:success] = "thank you for your service o7"
      redirect_to [ :admin, @shop_order ]
    end

    private

    def group_all(scope)
      orders = scope.includes(:user, :shop_item).to_a
      grouped = orders.group_by(&:user)

      grouped.map do |user, user_orders|
      total_shells = user_orders.sum { |o| o.frozen_item_price * o.quantity }
      total_items = user_orders.sum(&:quantity)

      {
        user: user,
        orders: user_orders.sort_by(&:created_at),
        total_shells: total_shells,
        total_items: total_items,
        address: user_orders.first&.frozen_address || {}
      }
      end.sort_by { |group| -group[:orders].size }
    end

    def ensure_authorized_user
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end

    def set_shop_order
      @shop_order = scope.find(params[:id])
    end

    def get_stats
      b = scope
      b = b.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" }) unless params[:show_free_stickers] == "true"
      all_s = b
      week_s = b.where("shop_orders.created_at >= ?", 1.week.ago)

      @c = {
        pending: all_s.where(aasm_state: "pending").count,
        awaiting_fulfillment: all_s.where(aasm_state: "awaiting_periodical_fulfillment").count,
        fulfilled: week_s.where(aasm_state: "fulfilled").count,
        rejected: week_s.where(aasm_state: "rejected").count
      }
      @c[:in_verification_limbo] = all_s.where(aasm_state: "in_verification_limbo").count if params[:show_free_stickers] == "true"

      mf = week_s.joins(:shop_item)
            .where(shop_items: { type: ShopItem::MANUAL_FULFILLMENT_TYPES.map(&:name) })
            .where(aasm_state: "fulfilled")
            .where.not(fulfilled_at: nil)
            .where.not(awaiting_periodical_fulfillment_at: nil)

      @f = mf.average("EXTRACT(EPOCH FROM fulfilled_at - shop_orders.created_at)")&.to_i
      @a = week_s.where.not(awaiting_periodical_fulfillment_at: nil)
            .average("EXTRACT(EPOCH FROM awaiting_periodical_fulfillment_at - shop_orders.created_at)")&.to_i
      @d = week_s.where(aasm_state: "fulfilled")
            .where.not(awaiting_periodical_fulfillment_at: nil)
            .where.not(fulfilled_at: nil)
            .average("EXTRACT(EPOCH FROM fulfilled_at - awaiting_periodical_fulfillment_at)")&.to_i
    end

    def dur(sec)
      return "--:--:--" unless sec
      hours = sec / 3600
      minutes = (sec % 3600) / 60
      secs = sec % 60
      sprintf("%02d:%02d:%02d", hours, minutes, secs)
    end
    helper_method :dur
  end
end
