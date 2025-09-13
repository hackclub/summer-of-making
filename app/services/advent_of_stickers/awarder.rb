# frozen_string_literal: true

module AdventOfStickers
  class Awarder
    REGULAR_THRESHOLD_SECONDS = 15 * 60
    SPECIAL_THRESHOLD_SECONDS = 4 * 60 * 60

    # on every devlog, we check if time across every devlog that was done today across all projects is greater than the threshold. we pluck the hackatime project keys and get the total seconds for today. keys and do a direct query to hackatime to get the total seconds for today.
    def self.award_for_devlog(devlog)
      user = devlog.user
      return unless user && Flipper.enabled?(:advent_of_stickers, user)

      today = Time.zone.today

      stickers_today = ShopItem::AdventSticker.enabled.where(unlock_on: today)
      return if stickers_today.blank?

      day_start = Time.zone.now.beginning_of_day
      day_end = day_start.end_of_day

      keys = Devlog.where(user_id: user.id, created_at: day_start..day_end)
                   .pluck(:hackatime_projects_key_snapshot)
                   .flatten
                   .compact
                   .uniq

      # if keys is blank, use the devlog's hackatime project keys
      keys = Array(devlog.hackatime_projects_key_snapshot).compact if keys.blank?
      return if keys.blank? || user.slack_id.blank?

      project_keys_string = keys.join(",")
      encoded_project_keys = URI.encode_www_form_component(project_keys_string)
      start_time_iso = day_start.utc.iso8601
      url = "https://hackatime.hackclub.com/api/v1/users/#{user.slack_id}/stats?filter_by_project=#{encoded_project_keys}&start_date=#{start_time_iso}&features=projects&total_seconds=true"

      headers = { "RACK_ATTACK_BYPASS" => ENV["HACKATIME_BYPASS_KEYS"] }.compact
      response = Faraday.get(url, nil, headers)
      return unless response.success?

      data = JSON.parse(response.body) rescue {}
      devlogged_today_seconds = data.dig("total_seconds").to_i

      target_sticker = if devlogged_today_seconds >= SPECIAL_THRESHOLD_SECONDS
        stickers_today.find_by(special: true) || stickers_today.find_by(special: false)
      elsif devlogged_today_seconds >= REGULAR_THRESHOLD_SECONDS
        stickers_today.find_by(special: false)
      end

      return unless target_sticker

      award = UserAdventSticker.create_with(earned_on: today, devlog_id: devlog.id).find_or_create_by(
        user_id: user.id,
        shop_item_id: target_sticker.id
      )

      if award.previously_new_record?
        image_url = target_sticker.image.url

        # DM user
        if user.slack_id.present?
          header = {
            type: "section",
            text: { type: "mrkdwn", text: "You just earned today’s Advent sticker: *#{target_sticker.name}*! :yay:" }
          }
          blocks = image_url.present? ? [ header, { type: "image", image_url: image_url, alt_text: target_sticker.name } ] : [ header ]
          SendSlackDmJob.perform_later(user.slack_id, nil, blocks: blocks)
        end

        # Channel announce
        channel_id = "C015M4L9AHW"
        if channel_id.present?
          header = {
            type: "section",
            text: { type: "mrkdwn", text: "#{user.display_name} just unlocked today’s sticker: *#{target_sticker.name}*! :partyparrot:" }
          }
          blocks = image_url.present? ? [ header, { type: "image", image_url: image_url, alt_text: target_sticker.name } ] : [ header ]
          SendSlackDmJob.perform_later(channel_id, nil, blocks: blocks)
        end
      end
    rescue => e
      Rails.logger.error("Advent Awarder error for devlog #{devlog.id}: #{e.message}")
      Honeybadger.notify(e, context: { devlog_id: devlog.id, user_id: user&.id })
      nil
    end
  end
end
