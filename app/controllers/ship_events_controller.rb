class ShipEventsController < ApplicationController
  before_action :set_ship_event, only: [:feedback]

  def feedback
    respond_to do |format|
      format.json do
        if @ship_event.has_feedback?
          render json: { 
            feedback: @ship_event.feedback,
            ship_event_id: @ship_event.id 
          }
        else
          render json: { 
            error: "No feedback available" 
          }, status: 404
        end
      end
    end
  end

  private

  def set_ship_event
    @ship_event = ShipEvent.find(params[:id])
  end
end