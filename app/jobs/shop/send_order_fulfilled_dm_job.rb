class Shop::SendOrderFulfilledDmJob < ApplicationJob
  queue_as :default

  def perform(shop_order)
    blocks =
      AbstractSlackBlocksController.render(
        template: "shop_orders/fulfilled_notif",
        assigns: { shop_order: shop_order },
        formats: [ :slack_blocks ],
      )

    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))

    channel = Rails.cache.fetch("slack_channel_id_#{shop_order.user.slack_id}", expires_in: 1.hour) do
      response = client.conversations_open(users: shop_order.user.slack_id)
      response.channel.id
    end

    client.chat_postMessage(
      channel:,
      blocks:,
      as_user: true,
    )
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Failed to send Slack DM: #{e.message}")
    Honeybadger.notify(e, context: { user_id: user_id, message: message })
  end
end
