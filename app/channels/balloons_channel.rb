class BalloonsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "balloons"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
