# frozen_string_literal: true

class WrappedController < ApplicationController
  before_action :ensure_wrapped_enabled

  def show
    @wrapped = WrappedPresenter.new(current_user)
  end

  private

  def ensure_wrapped_enabled
    return if Flipper.enabled?(:wrapped, current_user)

    raise ActionController::RoutingError, "Not Found"
  end
end
