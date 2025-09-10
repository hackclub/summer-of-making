class Project::PostToMagicJob < ApplicationJob
  queue_as :default

  CHANNEL_ID = "C09E4NFHPJS"

  include Rails.application.routes.url_helpers

  def perform(project)
    client = Slack::Web::Client.new(token: ENV.fetch("SLACK_BOT_TOKEN", nil))

    client.chat_postMessage(
      channel: CHANNEL_ID,
      blocks: [
        {
          "type": "context",
          "elements": [
            {
              "type": "plain_text",
              "text": "magic reported!",
              "emoji": true
            }
          ]
        },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*<#{project_url(project, host: "https://summer.hackclub.com")}|#{project.title}>* by _#{project.user.display_name}_\n#{project.description}"
          },
          "accessory": {
            "type": "image",
            "image_url": project.banner.attached? ? project.banner.url : "https://crouton.net/crouton.png",
            "alt_text": "cute cat"
          }
        }
      ],
      as_user: true,
    )
  end
end
