module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    before_action :set_user, except: [ :index ]

    def index
      @pagy, @users = pagy(User.all)
    end

    def show
      @activities = @user.activities
    end
    def internal_notes
      @user.internal_notes = params[:internal_notes]
      @user.create_activity("edit_internal_notes", params: { note: params[:internal_notes] })
      @user.save!
      render :internal_notes, layout: false
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
