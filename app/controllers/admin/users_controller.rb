module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    before_action :set_user, except: [ :index ]

    def index
      @pagy, @users = pagy(User.all.order(id: :desc), items: 50)
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

    private

    def set_user
      @user = User.find(params[:id])
    end

    def payout_params
      params.require(:payout).permit(:amount, :reason)
    end
  end
end
