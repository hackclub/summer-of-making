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

  msg = "Hello there! :hii: Heidi and I have noticed you still have #{balance} shells left over! " \
            "The shop is closing in about 12 hours, and once it is closed, it is closed! " \
            "So if you want any last goodies, best get to stepping! :run-aaa: " \
            "If you have no need for your shells, you can <https://summer.hackclub.com/shop/items/258/buy|donate them> to others! " \
            "Happy spending, and from everyone on the team, thank you for being part of the Summer of Making! :ohneheart:"

  begin
    SendSlackDmJob.perform_later(user[:slack_id], msg)
    puts "queued message for #{user[:display_name]} (#{balance} shells)"
  rescue => e
    puts "FUCKING HELL MATE #{user[:display_name]}: #{e.message}"
  end

  sleep(0.1) # dont kill prod
end

puts "\nDone! #{output.count} messages in the barrel."
