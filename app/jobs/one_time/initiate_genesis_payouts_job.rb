class OneTime::InitiateGenesisPayoutsJob < ApplicationJob
  queue_as :default

  def perform(dry_run: false)
    return if Payout.where(payable_type: "ShipEvent").any? # Protect from running twice

    ActiveRecord::Base.transaction do
      # Find projects that have ship events and enough votes
      qualifying_projects = Project.joins(:ship_events, :vote_changes)
      .where(vote_changes: { project_vote_count: 18.. })
      .distinct
      # .limit(200)

      puts "Found #{qualifying_projects.count} qualifying projects"

      qualifying_projects.find_each do |p|
        puts "Processing project #{p.id}: #{p.title}"
        puts "  Ship events: #{p.ship_events.count}"

        p.issue_payouts(all_time: true)
      end

      total_payouts = Payout.where(payable_type: "ShipEvent").count
      puts "Total payouts created: #{total_payouts}"

      export_in_csv if dry_run
      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  def export_in_csv
    require "csv"

    # First collect all data to validate consistency
    payout_data = []
    vote_count_bounds = {}

    Payout.where(payable_type: "ShipEvent").find_each do |p|
      ship_event = p.payable
      project = ship_event.project

      # Get the cumulative vote count at the time this ship event was paid out
      # This should be the vote count when this ship event received its 18th vote
      votes_before_ship = VoteChange.where(project: project).where("created_at <= ?", ship_event.created_at).count

      # For genesis payouts, we use the project's final ELO rating and full ELO range
      # Still track cumulative vote count for consistency tracking
      cumulative_vote_count_at_payout = votes_before_ship + 18

      # Genesis: use full ELO range across all projects ever
      min, max = [VoteChange.minimum(:elo_after), VoteChange.maximum(:elo_after)]

      # Genesis: use project's final ELO rating (not ELO at 18th vote)
      current_elo = project.rating
      elo_percentile = min == max ? 0.0 : (current_elo - min) / (max - min).to_f

      # Genesis consistency check: all projects should have the same ELO bounds (full range)
      if vote_count_bounds[:genesis_bounds]
        existing_min, existing_max = vote_count_bounds[:genesis_bounds]
        if existing_min != min || existing_max != max
          raise "INCONSISTENT GENESIS ELO BOUNDS! Project #{project.id} has bounds [#{min}, #{max}] but previous project had bounds [#{existing_min}, #{existing_max}]"
        end
      else
        vote_count_bounds[:genesis_bounds] = [ min, max ]
      end

      if min > current_elo || max < current_elo
        raise "INCONSISTENT ELO BOUNDS! Project #{project.id} with #{cumulative_vote_count_at_payout} cumulative votes has bounds [#{min}, #{max}] but current ELO is #{current_elo}"
      end

      payout_data << [
        project.title,
        project.id,
        "https://summer.hackclub.com/projects/#{project.id}",
        ship_event.id,
        p.amount,
        current_elo,
        max,
        min,
        elo_percentile,
        project.total_votes,
        votes_before_ship
      ]
    end

    # If we get here, all bounds are consistent, so write the CSV
    CSV.open("genesis_payouts.csv", "w") do |csv|
      csv << [ "Project", "Project ID", "Project Link", "Ship ID", "Payout amount", "final elo", "global elo max", "global elo min", "elo percentile", "total votes", "votes before ship" ]
      payout_data.each { |row| csv << row }
    end

    puts "✅ ELO bounds consistency check passed!"
  end
end
