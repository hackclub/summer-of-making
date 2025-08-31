class VoteProcessingService
  K_FACTOR = 32 # Can change this – can also re-calc this.

  def initialize(vote)
    @vote = vote
  end

  def process
    reason = low_quality_reason
    if reason
      updates = {
        status: "invalid",
        invalid_reason: reason,
        marked_invalid_at: Time.current
      }
      updates[:is_low_quality] = true if Vote.column_names.include?("is_low_quality")
      @vote.update!(updates)
      return
    end

    if @vote.winning_project_id.nil?
      process_tie
    else
      process_winner_loser_vote
    end
  end

  def process_winner_loser_vote
    winner_project_id = @vote.winning_project_id.to_i
    loser_project_id = get_loser_project_id(winner_project_id)

    return unless winner_project_id && loser_project_id

    winner = Project.find(winner_project_id)
    loser = Project.find(loser_project_id)

    winner_elo_before = winner.rating
    loser_elo_before = loser.rating

    expected_winner_score = expected_score(winner_elo_before, loser_elo_before)
    expected_loser_score = expected_score(loser_elo_before, winner_elo_before)

    winner_elo_delta = (K_FACTOR * (1 - expected_winner_score)).round
    loser_elo_delta = (K_FACTOR * (0 - expected_loser_score)).round

    winner_elo_after = winner_elo_before + winner_elo_delta
    loser_elo_after = loser_elo_before + loser_elo_delta

    winner.update!(rating: winner_elo_after)
    loser.update!(rating: loser_elo_after)

    create_vote_change(winner, winner_elo_before, winner_elo_after, winner_elo_delta, "win")
    create_vote_change(loser, loser_elo_before, loser_elo_after, loser_elo_delta, "loss")
  end

  def process_tie
    project_1 = @vote.ship_event_1.project
    project_2 = @vote.ship_event_2.project

    project_1_elo_before = project_1.rating
    project_2_elo_before = project_2.rating

    expected_project_1_score = expected_score(project_1_elo_before, project_2_elo_before)
    expected_project_2_score = expected_score(project_2_elo_before, project_1_elo_before)

    project_1_elo_delta = (K_FACTOR * (0.5 - expected_project_1_score)).round # 0.5 when tie
    project_2_elo_delta = (K_FACTOR * (0.5 - expected_project_2_score)).round

    project_1_elo_after = project_1_elo_before + project_1_elo_delta
    project_2_elo_after = project_2_elo_before + project_2_elo_delta

    project_1.update!(rating: project_1_elo_after)
    project_2.update!(rating: project_2_elo_after)

    create_vote_change(project_1, project_1_elo_before, project_1_elo_after, project_1_elo_delta, "tie")
    create_vote_change(project_2, project_2_elo_before, project_2_elo_after, project_2_elo_delta, "tie")
  end

  private

  def low_quality_reason
    if @vote.time_spent_voting_ms && @vote.time_spent_voting_ms <= 30_000
      return "too_fast_under_30s"
    end

    if @vote.explanation.present?
      duplicate_exists = Vote.where(user_id: @vote.user_id, explanation: @vote.explanation)
                             .where.not(id: @vote.id)
                             .exists?
      return "duplicate_explanation_for_user" if duplicate_exists
    end

    nil
  end

  def get_loser_project_id(winner_id)
    project_1_id = @vote.ship_event_1.project_id
    project_2_id = @vote.ship_event_2.project_id

    return project_2_id if project_1_id == winner_id
    return project_1_id if project_2_id == winner_id

    nil # Should not happen if winner_id is valid
  end

  def expected_score(rating_a, rating_b)
    1.0 / (1.0 + 10.0**((rating_b - rating_a) / 400.0))
  end

  def create_vote_change(project, elo_before, elo_after, elo_delta, result)
    @vote.vote_changes.create!(
      project: project,
      elo_before: elo_before,
      elo_after: elo_after,
      elo_delta: elo_delta,
      result: result,
      project_vote_count: project.total_votes + 1
    )
  end
end
