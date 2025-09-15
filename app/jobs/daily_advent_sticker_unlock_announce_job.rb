# frozen_string_literal: true

class DailyAdventStickerUnlockAnnounceJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    channel_id = "C015M4L9AHW"
    return if channel_id.blank?

    stickers = ShopItem::AdventSticker.enabled.where(unlock_on: date)
    return if stickers.blank?

    names = stickers.pluck(:name).join(", ")
    text = "Today’s Stickerlode sticker#{'s' if stickers.size > 1} unlocked: #{names}!"

    SendSlackDmJob.perform_later(channel_id, text)
  end
end
