# frozen_string_literal: true

class SendSlackDmJob < ApplicationJob
  queue_as :latency_5m

  def perform(recipient_id, message = nil, blocks: nil)
    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))

    recipient = recipient_id.to_s
    if recipient.start_with?("C", "G", "D")
      channel_id = recipient
    else
      channel_id = Rails.cache.fetch("slack_channel_id_#{recipient}", expires_in: 1.hour) do
        response = client.conversations_open(users: recipient)
        response.channel.id
      end
    end

    params = { channel: channel_id, as_user: true }
    params[:text] = message if message.present?
    params[:blocks] = blocks if blocks.present?

    client.chat_postMessage(**params)
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Failed to send Slack DM: #{e.message}")
    Honeybadger.notify(e, context: { recipient_id: recipient_id, message: message, blocks: blocks })
  end
end
