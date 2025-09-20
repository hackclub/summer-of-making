class Admin::ShipEventsController < Admin::ApplicationController
  before_action :set_ship_event, only: [:regenerate_feedback]

  def regenerate_feedback
    result = @ship_event.regenerate_feedback
    status = result[:success] ? :ok : (result[:message].include?("check logs") ? 422 : 500)
    render json: result, status: status
  end

  private

  def set_ship_event
    @ship_event = ShipEvent.find(params[:id])
  end
end