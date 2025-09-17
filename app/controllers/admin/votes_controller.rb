module Admin
  class VotesController < ApplicationController
    before_action :set_vote

    def invalidate
      @vote.mark_invalid!(params[:reason], current_user)
      flash[:success] = "invalidated vote!"
      redirect_back(fallback_location: admin_root_path)
    end

    def uninvalidate
      @vote.mark_uninvalid!
      flash[:success] = "uninvalidated vote!"
      redirect_back(fallback_location: admin_root_path)
    end

    def set_vote
      @vote = Vote.find(params[:id])
    end
  end
end
