# frozen_string_literal: true

module Admin
  class ShopOrdersController < ApplicationController
    include Pagy::Backend
    before_action :set_shop_order, except: [ :index, :pending, :awaiting_fulfillment ]

    def scope
      ShopOrder.all.includes(:user, :shop_item)
    end

    def filtered_scope
      base_scope = scope

      # Hide free stickers orders by default unless explicitly requested
      unless params[:show_free_stickers] == "true"
        base_scope = base_scope.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" })
      end

      if params[:user_search].present?
        query = "%#{params[:user_search]}%"
        base_scope = base_scope.joins(:user).where(
          "users.display_name ILIKE ? OR users.email ILIKE ? OR users.slack_id ILIKE ?",
          query, query, query
        )
      end

      if params[:shop_item_id].present?
        base_scope = base_scope.where(shop_item_id: params[:shop_item_id])
      end

      if params[:status].present?
        base_scope = base_scope.where(aasm_state: params[:status])
      end

      if params[:date_from].present?
        base_scope = base_scope.where("created_at >= ?", Date.parse(params[:date_from]).beginning_of_day)
      end

      if params[:date_to].present?
        base_scope = base_scope.where("created_at <= ?", Date.parse(params[:date_to]).end_of_day)
      end

      case params[:sort]
      when "id_asc"
        base_scope = base_scope.order(id: :asc)
      when "id_desc"
        base_scope = base_scope.order(id: :desc)
      when "shells_asc"
        base_scope = base_scope.order(frozen_item_price: :asc)
      when "shells_desc"
        base_scope = base_scope.order(frozen_item_price: :desc)
      when "created_at_asc"
        base_scope = base_scope.order(created_at: :asc)
      when "created_at_desc"
        base_scope = base_scope.order(created_at: :desc)
      else
        base_scope = base_scope.order(created_at: :desc)
      end

      base_scope
    rescue Date::Error
      base_scope
    end

    def index
      @pagy, @shop_orders = pagy(filtered_scope)
      calculate_processing_stats
    end

    def pending
      @pagy, @shop_orders = pagy(filtered_scope.pending)
      calculate_processing_stats
      render :index, locals: { title: "pending " }
    end

    def awaiting_fulfillment
      @pagy, @shop_orders = pagy(filtered_scope.manually_fulfilled.awaiting_periodical_fulfillment)
      calculate_processing_stats
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

    def set_shop_order
      @shop_order = scope.find(params[:id])
    end

    def calculate_processing_stats
      # Calculate average time from pending to approved using activities
      pending_to_approved = scope.joins("LEFT JOIN activities ON activities.trackable_id = shop_orders.id AND activities.trackable_type = 'ShopOrder' AND activities.key = 'approve'")
                                 .where.not(aasm_state: "pending")
                                 .where.not("activities.created_at IS NULL")
                                 .average("EXTRACT(EPOCH FROM activities.created_at - shop_orders.created_at)")

      # Calculate average time from awaiting fulfillment to fulfilled
      awaiting_to_fulfilled = scope.where(aasm_state: "fulfilled")
                                   .where.not(awaiting_periodical_fulfillment_at: nil)
                                   .where.not(fulfilled_at: nil)
                                   .average("EXTRACT(EPOCH FROM fulfilled_at - awaiting_periodical_fulfillment_at)")

      @pending_to_approved_seconds = pending_to_approved&.to_i
      @awaiting_to_fulfilled_seconds = awaiting_to_fulfilled&.to_i

      base_scope_count = scope
      unless params[:show_free_stickers] == "true"
        base_scope_count = base_scope_count.joins(:shop_item).where.not(shop_items: { type: "ShopItem::FreeStickers" })
      end

      @counts = {
        pending: base_scope_count.where(aasm_state: "pending").count,
        awaiting_fulfillment: base_scope_count.where(aasm_state: "awaiting_periodical_fulfillment").count,
        fulfilled: base_scope_count.where(aasm_state: "fulfilled").count,
        rejected: base_scope_count.where(aasm_state: "rejected").count
      }

      if params[:show_free_stickers] == "true"
        @counts[:in_verification_limbo] = base_scope_count.where(aasm_state: "in_verification_limbo").count
      end
    end

    def format_duration(seconds)
      return "--:--:--" unless seconds

      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      secs = seconds % 60
      sprintf("%02d:%02d:%02d", hours, minutes, secs)
    end
    helper_method :format_duration
  end
end
