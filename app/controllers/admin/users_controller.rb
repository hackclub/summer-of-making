module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    before_action :set_user, except: [ :index ]

    def index
      @pagy, @users = pagy(
        User
          .all
          .search(params[:search]&.sub("mailto:", ""))
          .order(id: :desc),
        items: 50)
    end

    def show
      @activities = @user.activities.order(created_at: :desc).includes(:owner)
      @payouts = @user.payouts.order(created_at: :desc).includes(:payable)
    end
    def internal_notes
      @user.internal_notes = params[:internal_notes]
      @user.create_activity("edit_internal_notes", params: { note: params[:internal_notes] })
      @user.save!
      render :internal_notes, layout: false
    end

    def create_payout
      parameters = payout_params
      unless parameters[:reason].present?
        return redirect_to(admin_user_path(@user), notice: "Please provide a reason!")
      end
      @payout = @user.payouts.build(parameters.merge(payable: @user))

      begin
        @payout.save!
        @user.create_activity("manual_payout", parameters:)
        flash[:success] = "Successfully created payout!"
        redirect_to admin_user_path(@user)
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_user_path, notice: e.message
      end
    end

    def nuke_idv_data
      @user.nuke_idv_data!
      flash[:success] = "what have you done"
      redirect_to admin_user_path(@user)
    end

    def cancel_card_grants
      CancelUserCardGrantsJob.perform_later(@user)
      @user.create_activity("cancel_card_grants")
      flash[:success] = "Card grant cancellation job has been queued"
      redirect_to admin_user_path(@user)
    end

    def freeze
      @user.update!(freeze_shop_activity: true)
      @user.create_activity("freeze")
      flash[:success] = "they are now entombed icily!"
      redirect_to admin_user_path(@user)
    end

    def defrost
      @user.update!(freeze_shop_activity: false)
      @user.create_activity("defrost")
      flash[:success] = "please let them thaw for a few hours..."
      redirect_to admin_user_path(@user)
    end

    def give_black_market
      @user.update!(has_black_market: true)
      @user.create_activity("give_black_market")
      flash[:success] = "they're in!"
      redirect_back_or_to admin_user_path(@user)
    end

    def take_away_black_market
      @user.update!(has_black_market: false)
      @user.create_activity("take_away_black_market")
      flash[:success] = "unfortunate."
      redirect_to admin_user_path(@user)
    end

    def grant_ship_certifier
      if @user.ship_certifier?
        flash[:notice] = "#{@user.email} nothing changed, they already have ship certifier permissions"
      else
        @user.add_permission("shipcert")
        @user.create_activity("grant_ship_certifier")
        flash[:success] = "gotcha, granted rights to #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    def revoke_ship_certifier
      unless @user.ship_certifier?
        flash[:notice] = "#{@user.email} nothing changed, they don't have ship certifier permissions"
      else
        @user.remove_permission("shipcert")
        @user.create_activity("revoke_ship_certifier")
        flash[:success] = "gotcha, revoked rights from #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def payout_params
      params.require(:payout).permit(:amount, :reason)
    end
  end
end
