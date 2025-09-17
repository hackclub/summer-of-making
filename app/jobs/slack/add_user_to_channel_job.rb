class Slack::AddUserToChannelJob < ApplicationJob
  queue_as :default

  def perform(user, channel_id)
    client = Slack::Web::Client.new(token: Rails.application.credentials.shadypheus.slack_token)
    client.conversations_invite(channel: channel_id, users: user.slack_id)
  end
end
