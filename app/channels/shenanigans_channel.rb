class ShenanigansChannel < ApplicationCable::Channel
  def subscribed
    stream_from "shenanigans"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
