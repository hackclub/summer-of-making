class OneTime::ReleaseEscrowedPayoutsJob < ApplicationJob
  queue_as :default
  # votes/20 then take ships and voial!
  def perform(dry_run: true, user_ids: nil)
    scope = Payout.where(payable_type: "ShipEvent", escrowed: true)
    scope = scope.where(user_id: user_ids) if user_ids.present?

    user_ids_with_escrow = scope.select(:user_id).distinct.pluck(:user_id)
    puts "Found #{user_ids_with_escrow.size} users with escrowed ShipEvent payouts to review"

    changed_users = 0
    total_released = 0
    total_released_amount = 0

    user_ids_with_escrow.each do |uid|
      user = User.find_by(id: uid)
      next unless user

      votes_count = user.votes.active.count
      ships_covered = (votes_count / 20).to_i

      approved_ships = user.ship_events
                           .includes(project: :ship_certifications)
                           .order(created_at: :asc)
                           .select { |se| se.project.latest_ship_certification&.approved? }

      next if approved_ships.empty? || ships_covered <= 0

      ships_to_release = approved_ships

      release_candidates = ships_to_release.flat_map do |ship|
        ship.payouts
            .where(escrowed: true)
            .where("amount > 0")
            .to_a
      end

      next if release_candidates.empty?

      released_count = 0
      released_amount = 0

      release_candidates.each do |p|
        released_count += 1
        released_amount += p.amount
        unless dry_run
          p.update!(escrowed: false)
          if user.slack_id.present?
            ship = p.payable
            project = ship.project
            position = project.ship_events.order(:created_at).pluck(:id).index(ship.id).to_i + 1
            ordinal = position.ordinalize
            amount_i = p.amount.to_i
            message = "Your payout of #{amount_i} shells for your #{ordinal} ship event on #{project.title} was released!"
            SendSlackDmJob.perform_later(user.slack_id, message)
          end
        end
      end

      changed_users += 1 if released_count > 0
      total_released += released_count
      total_released_amount += released_amount

      puts "User #{user.id} (#{user.display_name}) — votes=#{votes_count}, approved_ships=#{approved_ships.size}, ships_covered=#{ships_covered}, ships_released=#{ships_to_release.size}, payouts_released=#{released_count}, released_amount=#{released_amount}#{dry_run ? ' (dry run)' : ''}"
    end

    puts "u changed: #{changed_users}, payouts released: #{total_released}, amount released: #{total_released_amount}#{dry_run ? ' (dry run)' : ''}"
  end
end
