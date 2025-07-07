# frozen_string_literal: true

namespace :users do
  # we don't perform any actions, yet.
  desc "Assess damage for buggy code"
  task assess_damage_ig: :environment do
    # July 2, 2025 4:50 PM EST, but we're checking from July 2, 2025 12:00 AM EST just to be safe.
    cutoff_date = Time.zone.parse("2025-07-02 00:00:00 EST")
    end_date = Time.zone.parse("2025-07-07 00:00:00 EST") # just to be safe.

    users_since_july_2 = User.where("created_at >= ?", cutoff_date).where("created_at <= ?", end_date).where.not(identity_vault_id: nil)

    puts "Total users created since cutoff_date: #{users_since_july_2.count}"
    puts

    stats = {
      total_users: users_since_july_2.count,
      pending: 0,
      needs_resubmission: 0,
      verified: 0,
      ineligible: 0,
      error_checking: 0,
      has_free_stickers: 0,
      free_stickers_pending: 0,
      free_stickers_fulfilled: 0,
      free_stickers_awaiting: 0,
      free_stickers_in_limbo: 0,
      actions_needed: 0
    }

    actions_log = []

    puts "Checking each user..."
    puts "-" * 80

    users_since_july_2.find_each do |user|
      puts "User ID: #{user.id}, Slack ID: #{user.slack_id}, Email: #{user.email}"
      puts "  IDV ID: #{user.identity_vault_id || 'None'}"

      begin
        verification_status = user.verification_status
        puts "  Verification Status: #{verification_status}"

        case verification_status
        when :pending
          stats[:pending] += 1
        when :needs_resubmission
          stats[:needs_resubmission] += 1
        when :verified
          stats[:verified] += 1
        when :ineligible
          stats[:ineligible] += 1
        end
      rescue => e
        puts "  ERROR checking verification status: #{e.message}"
        stats[:error_checking] += 1
        verification_status = :error
      end

      # check for free stickers
      free_stickers_orders = user.shop_orders.joins(:shop_item).where(shop_items: { type: "ShopItem::FreeStickers" })

      if free_stickers_orders.any?
        stats[:has_free_stickers] += 1

        free_stickers_orders.each do |order|
          puts "Order ID: #{order.id}, Status: #{order.aasm_state}, Created: #{order.created_at}"

          case order.aasm_state
          when "pending"
            stats[:free_stickers_pending] += 1
          when "fulfilled"
            stats[:free_stickers_fulfilled] += 1
          when "awaiting_periodical_fulfillment"
            stats[:free_stickers_awaiting] += 1
          when "in_verification_limbo"
            stats[:free_stickers_in_limbo] += 1
          end
        end
      else
        puts "  Free Stickers Orders: None"
      end

      # determine actions that need to be taken – nothing is being done, yet.
      if verification_status == :ineligible || verification_status == :needs_resubmission
        stats[:actions_needed] += 1

        actions = []

        if free_stickers_orders.any?
          free_stickers_orders.each do |order|
            if order.aasm_state == "fulfilled"
              actions << "LOG: Free stickers order #{order.id} was already fulfilled - cannot cancel"
            elsif order.aasm_state != "rejected"
              actions << "CANCEL: Free stickers order #{order.id} (currently #{order.aasm_state})"
            end
          end
        end

        actions << "DOWNGRADE: Account to MCG"

        # Slack DM action
        message = if verification_status == :ineligible
          "blah blah i fucked up sorry - you're ineligible"
        else
          "blah blah i fucked up sorry - you need to resubmit"
        end
        actions << "SEND_DM: '#{message}'"

        actions_log << {
          user_id: user.id,
          slack_id: user.slack_id,
          email: user.email,
          verification_status: verification_status,
          actions: actions
        }

        puts "ACTIONS NEEDED FOR USER:"
        actions.each { |action| puts "    - #{action}" }
      end

      puts
    end

    puts "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    puts "Total users since July 2: #{stats[:total_users]}"
    puts
    puts "Verification Status Breakdown:"
    puts "  - Pending: #{stats[:pending]}"
    puts "  - Needs resubmission: #{stats[:needs_resubmission]}"
    puts "  - Verified: #{stats[:verified]}"
    puts "  - Ineligible: #{stats[:ineligible]}"
    puts "  - Error checking: #{stats[:error_checking]}"
    puts
    puts "Free Stickers Orders:"
    puts "  - Users with free stickers: #{stats[:has_free_stickers]}"
    puts "  - Pending orders: #{stats[:free_stickers_pending]}"
    puts "  - Fulfilled orders: #{stats[:free_stickers_fulfilled]}"
    puts "  - Awaiting fulfillment: #{stats[:free_stickers_awaiting]}"
    puts "  - In verification limbo: #{stats[:free_stickers_in_limbo]}"
    puts
    puts "Actions Required:"
    puts "  - Users needing action: #{stats[:actions_needed]}"
    puts "  - Users that would be unaffected: #{stats[:total_users] - stats[:actions_needed]}"
    puts

    puts "=" * 80
    puts "done."
    puts "=" * 80
  end

  desc "fix ysws_verified"
  task fix_ysws_verified: :environment do
    users_with_ysws_verified = User.where.not(ysws_verified: nil)

    users_with_ysws_verified.find_each do |user|
      idv_data = user.fetch_idv
      
      if idv_data[:verification_status] != "verified" && !idv_data[:ysws_eligible]
        puts "fixing ysws_verified for user #{user.id}"
        user.update(ysws_verified: false)
      end
    end
  end

  # run fix_ysws_verified first
  desc "Demote users created since July 2 and cancel free stickers orders"
  task demote_and_cancel_free_stickers: :environment do
    # July 2, 2025 4:50 PM EST, but we're checking from July 2, 2025 12:00 AM EST just to be safe.
    cutoff_date = Time.zone.parse("2025-07-02 00:00:00 EST")
    end_date = Time.zone.parse("2025-07-07 00:00:00 EST") # just to be safe.

    users_since_july_2 = User.where("created_at >= ?", cutoff_date)
                              .where("created_at <= ?", end_date)
                              .where.not(identity_vault_id: nil)

    puts "Starting remediation for #{users_since_july_2.count} users created since July 2"
    puts "=" * 80

    stats = {
      total_processed: 0,
      ineligible: 0,
      needs_resubmission: 0,
      verified: 0,
      pending: 0,
      error_checking: 0,
      orders_canceled: 0,
      orders_already_fulfilled: 0,
      accounts_downgraded: 0,
      errors: 0
    }

    users_since_july_2.find_each do |user|
      begin
        stats[:total_processed] += 1
        puts "Processing User ID: #{user.id}, Slack ID: #{user.slack_id}, Email: #{user.email}"

        # Check verification status
        verification_status = user.verification_status
        puts "  Verification Status: #{verification_status}"

        case verification_status
        when :pending
          stats[:pending] += 1
          puts "  User is pending - no action needed"
          next
        when :verified
          stats[:verified] += 1
          puts "  User is verified - no action needed"
          next
        when :ineligible
          stats[:ineligible] += 1
        when :needs_resubmission
          stats[:needs_resubmission] += 1
        else
          puts "  Unknown verification status: #{verification_status}"
          stats[:error_checking] += 1
          next
        end

        free_stickers_orders = user.shop_orders.joins(:shop_item)
                                   .where(shop_items: { type: "ShopItem::FreeStickers" })

        free_stickers_orders.each do |order|
          puts "  Found free stickers order #{order.id} with status: #{order.aasm_state}"

          case order.aasm_state
          when "fulfilled"
            puts "    Order already fulfilled - logging but cannot cancel"
            stats[:orders_already_fulfilled] += 1
          when "rejected"
            puts "    Order already rejected - no action needed"
          else
            puts "    Canceling order #{order.id}"
            order.reject!
            stats[:orders_canceled] += 1
          end
        end

        puts "  Downgrading account to Multi-channel guest"

        # sending stuff to neon's slack not yet implemented

        # if response.ok? stats[:accounts_downgraded] += 1

        # TODO: figure out what to do with devlogs, projects, ship_events, etc.

        puts "Remediation complete for user #{user.id}"

      rescue => e
        puts "Error processing user #{user.id}: #{e.message}"
        stats[:errors] += 1
      end

      puts
    end

    puts "=" * 80
    puts "DONE"
    puts "=" * 80
    puts "Total users processed: #{stats[:total_processed]}"
    puts "Verification status breakdown:"
    puts "  - Ineligible: #{stats[:ineligible]}"
    puts "  - Needs resubmission: #{stats[:needs_resubmission]}"
    puts "  - Verified (no action): #{stats[:verified]}"
    puts "  - Pending (no action): #{stats[:pending]}"
    puts "  - Error checking: #{stats[:error_checking]}"
    puts
    puts "Actions taken:"
    puts "  - Orders canceled: #{stats[:orders_canceled]}"
    puts "  - Orders already fulfilled (logged): #{stats[:orders_already_fulfilled]}"
    puts "  - Errors encountered: #{stats[:errors]}"
    puts
    puts "=" * 80
  end
end
