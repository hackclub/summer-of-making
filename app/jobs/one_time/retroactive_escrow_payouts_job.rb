class OneTime::RetroactiveEscrowPayoutsJob < ApplicationJob
  queue_as :default

  # Retroactively mark ShipEvent payouts as escrowed for users who haven't met
  # the voting requirement yet. We only escrow whole payouts and cap by current
  # available balance to avoid making balances negative.
  #
  # Options:
  # - dry_run: if true, only logs intended changes
  # - user_ids: optional array of user IDs to limit scope
  def perform(dry_run: true, user_ids: nil)
    scope = Payout.where(payable_type: "ShipEvent", escrowed: false)
    scope = scope.where(user_id: user_ids) if user_ids.present?

    users_with_candidates = scope.select(:user_id).distinct.pluck(:user_id)
    puts "Found #{users_with_candidates.size} users with non-escrowed ShipEvent payouts"

    changed_users = 0
    total_payouts_flagged = 0
    total_amount_flagged = 0

    users_with_candidates.each do |uid|
      user = User.find_by(id: uid)
      next unless user

      next if user.has_met_voting_requirement?

      available_balance = user.balance
      next if available_balance <= 0

      candidate_payouts = user.payouts
                              .where(payable_type: "ShipEvent", escrowed: false)
                              .where("amount > 0")
                              .order(created_at: :desc)

      candidate_sum = candidate_payouts.sum(:amount)
      target_to_escrow = [ candidate_sum, available_balance ].min
      next if target_to_escrow <= 0

      puts "User #{user.id} (#{user.display_name}) — balance=#{available_balance}, candidates=#{candidate_sum}, target=#{target_to_escrow}"

      flagged_count = 0
      flagged_amount = 0

      candidate_payouts.each do |p|
        break if flagged_amount + p.amount > target_to_escrow

        flagged_count += 1
        flagged_amount += p.amount

        unless dry_run
          p.update!(escrowed: true)
        end
      end

      next if flagged_count.zero?

      changed_users += 1
      total_payouts_flagged += flagged_count
      total_amount_flagged += flagged_amount

      puts "  → Flagged #{flagged_count} payouts totaling #{flagged_amount} for escrow" \
           + (dry_run ? " (dry run)" : "")

      # Notify the user via Slack DM when escrow is applied
      unless dry_run
        if user.slack_id.present?
          remaining_votes = [ user.votes_required_for_release - user.votes.active.count, 0 ].max
          message = <<~MSG
            Heads up! We moved #{flagged_amount.to_i} shells from your recent ship payouts into escrow because you haven't finished voting yet.

            Vote #{remaining_votes} more #{remaining_votes == 1 ? 'time' : 'times'} to release them: https://summer.hackclub.com/votes/new

            Thanks for helping keep payouts fair for everyone!
          MSG
          SendSlackDmJob.perform_later(user.slack_id, message)
        end
      end
    end

    puts "Done. Users changed: #{changed_users}, payouts flagged: #{total_payouts_flagged}, amount flagged: #{total_amount_flagged}#{dry_run ? ' (dry run)' : ''}"
  end
end
