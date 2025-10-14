#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../config/environment"

output = User
  .joins(:payouts)
  .where(payouts: { escrowed: false })
  .where(is_banned: false)
  .group("users.id")
  .having("SUM(payouts.amount) > 0")
  .pluck("users.id", "users.slack_id", "users.display_name", "SUM(payouts.amount)")
  .map { |id, slack_id, display_name, balance| { id: id, slack_id: slack_id, display_name: display_name, balance: balance } }
  .sort_by { |u| -u[:balance].to_f }

puts "still with money! #{output.count} users"

output.each do |user|
  balance = user[:balance].to_f.round
  balance = balance.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse

  msg = "Hey! :hi-bear: This is the final message you will get about this, but the shop will close in under four hours and you still have #{balance} shells left! " \
            ":siren-real: This is your last chance unless you have an extreme situation in which you cannot place your orders by then. " \
            "If this applies to you, please DM <@U080A3QP42C>. If you have no need for your shells, you can <https://summer.hackclub.com/shop/items/258/buy|donate them> to others! " \
            "Thank you, #{user[:display_name]}! :ohneheart:"

  begin
    SendSlackDmJob.perform_later(user[:slack_id], msg)
    puts "queued message for #{user[:display_name]} (#{balance} shells)"
  rescue => e
    puts "FUCKING HELL MATE #{user[:display_name]}: #{e.message}"
  end

  sleep(0.1) # dont kill prod
end

puts "\nDone! #{output.count} messages in the barrel."
