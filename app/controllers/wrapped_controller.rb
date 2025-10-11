# frozen_string_literal: true

class WrappedController < ApplicationController
  skip_before_action :authenticate_user!, only: :share

  before_action :set_wrapped_user
  before_action :ensure_wrapped_enabled

  def show
    @wrapped_user.ensure_wrapped_share_token!
    @wrapped = WrappedPresenter.new(@wrapped_user)
    @viewer_is_owner = true
  end

  def share
    @wrapped = WrappedPresenter.new(@wrapped_user)
    @viewer_is_owner = current_user.present? && current_user == @wrapped_user
    render :show
  end

  private

  def set_wrapped_user
    if action_name == "share"
      @wrapped_user = User.find_by!(wrapped_share_token: params[:share_token])
    else
      raise ActionController::RoutingError, "Not Found" unless current_user

      @wrapped_user = current_user
    end
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end

  def ensure_wrapped_enabled
    return if Flipper.enabled?(:wrapped, @wrapped_user)

    raise ActionController::RoutingError, "Not Found"
  end
end
