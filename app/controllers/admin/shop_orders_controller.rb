# frozen_string_literal: true

module Admin
  class ShopOrdersController < ApplicationController
    include Pagy::Backend
    before_action :set_shop_order, except: [ :index, :pending ]

    def scope
      ShopOrder.all.includes(:user, :shop_item).order(created_at: :desc)
    end

    def index
      @pagy, @shop_orders = pagy(scope)
    end

    def pending
      @pagy, @shop_orders = pagy(scope.pending)
      render :index, locals: { title: "pending " }
    end

    def awaiting_fulfillment
      @pagy, @shop_orders = pagy(scope.pending)
      render :index, locals: { title: "pending " }
    end

    def show
      @activities = @shop_order.activities
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
      redirect_to [ :admin, @shop_order ]
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
      redirect_to @shop_order, notice: "you need to provide a reference!" unless external_ref
      @shop_order.mark_fulfilled!(external_ref)
      @shop_order.create_activity("mark_fulfilled", parameters: { external_ref: })
      flash[:success] = "thank you for your service o7"
      redirect_to [ :admin, @shop_order ]
    end

    private

    def set_shop_order
      @shop_order = scope.find(params[:id])
    end
  end
end
