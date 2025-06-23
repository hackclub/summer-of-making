class ShipEventFeedbacksController < ApplicationController
  before_action :require_admin!

  def index
    @projects = Project.joins(:ship_events)
                      .includes([ :user ])
                      .left_joins(ship_events: :ship_event_feedback)
                      .where(ship_events: { ship_event_feedbacks: { id: nil } })
                      .distinct
                      .includes(ship_events: :ship_event_feedback)
  end

  def new
    @feedback = ShipEventFeedback.new(ship_event_id: params[:ship_event_id])
    puts "WORH", @feedback.inspect
  end
end
