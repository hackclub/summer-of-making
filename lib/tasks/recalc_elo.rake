# frozen_string_literal: true

namespace :votes do
  desc "elo recalc"
  task recalc_elo: :environment do
    k_factor = 32
    base_rating = 1100

    expected = ->(ra, rb) { 1.0 / (1.0 + 10.0 ** ((rb - ra) / 400.0)) }

    dry_run = ENV.fetch("DRY_RUN", "true").to_s.downcase == "true"
    apply_ok = !dry_run && ENV["CONFIRM"].to_s == "apply"
    progress_every = 500

    ratings = Hash.new { |h, project_id| h[project_id] = base_rating }
    counts  = Hash.new(0)

    total = Vote.active.count
    processed = 0
    skipped = 0
    started_at = Time.current

    puts "[ELO] Total active votes: #{total}"

    ActiveRecord::Base.transaction do
      prev_paused = defined?(Flipper) ? Flipper.enabled?(:voting_paused) : false
      Flipper.enable(:voting_paused) if defined?(Flipper)
      # set to 1100
      Project.unscoped.update_all(rating: base_rating, updated_at: Time.current)
      puts "[ELO] Reset all project ratings to #{base_rating}"

      # sequentially process votes
      Vote.active.order(:created_at).includes(:vote_changes).find_each(batch_size: 1000) do |vote|
        changes = vote.vote_changes.to_a
        if changes.empty?
          skipped += 1
          next
        end

        wins = changes.select { |c| c.result == "win" }
        losses = changes.select { |c| c.result == "loss" }
        ties = changes.select { |c| c.result == "tie" }

        if wins.any? && losses.any?
          win_change = wins.first
          loss_change = losses.first
          winner_id = win_change.project_id
          loser_id = loss_change.project_id

          winner_before = ratings[winner_id]
          loser_before = ratings[loser_id]

          ew = expected.call(winner_before, loser_before)
          el = expected.call(loser_before, winner_before)

          winner_delta = (k_factor * (1 - ew)).round
          loser_delta  = (k_factor * (0 - el)).round

          winner_after = winner_before + winner_delta
          loser_after  = loser_before + loser_delta

          ratings[winner_id] = winner_after
          ratings[loser_id]  = loser_after
          counts[winner_id] += 1
          counts[loser_id]  += 1

          Project.unscoped.where(id: winner_id).update_all(rating: winner_after, updated_at: Time.current)
          Project.unscoped.where(id: loser_id).update_all(rating: loser_after, updated_at: Time.current)

          win_change.update_columns(elo_before: winner_before, elo_after: winner_after, elo_delta: winner_delta, project_vote_count: counts[winner_id], updated_at: Time.current)
          loss_change.update_columns(elo_before: loser_before,  elo_after: loser_after,  elo_delta: loser_delta,  project_vote_count: counts[loser_id],  updated_at: Time.current)

          processed += 1
          puts "[ELO][##{vote.id}] win/loss | W:#{winner_id} (#{winner_before}->#{winner_after}, Δ#{winner_delta}) | L:#{loser_id} (#{loser_before}->#{loser_after}, Δ#{loser_delta})"
        elsif ties.size >= 2
          a_change, b_change = ties.first(2)
          a_id = a_change.project_id
          b_id = b_change.project_id

          a_before = ratings[a_id]
          b_before = ratings[b_id]

          ea = expected.call(a_before, b_before)
          eb = expected.call(b_before, a_before)

          a_delta = (k_factor * (0.5 - ea)).round
          b_delta = (k_factor * (0.5 - eb)).round

          a_after = a_before + a_delta
          b_after = b_before + b_delta

          ratings[a_id] = a_after
          ratings[b_id] = b_after
          counts[a_id] += 1
          counts[b_id] += 1

          Project.unscoped.where(id: a_id).update_all(rating: a_after, updated_at: Time.current)
          Project.unscoped.where(id: b_id).update_all(rating: b_after, updated_at: Time.current)

          a_change.update_columns(elo_before: a_before, elo_after: a_after, elo_delta: a_delta, project_vote_count: counts[a_id], updated_at: Time.current)
          b_change.update_columns(elo_before: b_before, elo_after: b_after, elo_delta: b_delta, project_vote_count: counts[b_id], updated_at: Time.current)

          processed += 1
          puts "[ELO][##{vote.id}] tie | A:#{a_id} (#{a_before}->#{a_after}, Δ#{a_delta}) | B:#{b_id} (#{b_before}->#{b_after}, Δ#{b_delta})"
        else
          skipped += 1
        end

        if (processed + skipped) % progress_every == 0
          elapsed = Time.current - started_at
          rate = (processed + skipped) / [ elapsed, 0.001 ].max
          remaining = [ total - (processed + skipped), 0 ].max
          eta_sec = remaining / [ rate, 0.001 ].max
          eta_str = Time.at(eta_sec).utc.strftime("%H:%M:%S")
          puts "[ELO] Progress: #{processed + skipped}/#{total} (processed=#{processed}, skipped=#{skipped}) | rate=#{rate.round(1)}/s | ETA=#{eta_str}"
        end
      end

      unless apply_ok
        puts "\nDRY_RUN=true (default) or missing CONFIRM=apply: rolling back all changes."
        raise ActiveRecord::Rollback
      end
    ensure
      # Restore previous pause state
      if defined?(Flipper)
        if prev_paused
          Flipper.enable(:voting_paused)
        else
          Flipper.disable(:voting_paused)
        end
      end
    end

    total_elapsed = Time.current - started_at
    puts "[ELO] Done. Processed votes: #{processed}, skipped: #{skipped}, total=#{processed + skipped}/#{total}, elapsed=#{total_elapsed.round(1)}s"
  end
end
