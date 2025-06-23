# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_projects, only: %i[new create]
  before_action :check_identity_verification

  before_action :redirect_to_locked, except: [ :locked ] # For the first week

  def new
    @vote = Vote.new
    @user_vote_count = current_user.votes.count

    session[:vote_tokens] = {}

    @projects.each do |project|
      token = SecureRandom.hex(16)
      session[:vote_tokens][token] = {
        "project_id" => project.id,
        "user_id" => current_user.id,
        "expires_at" => 2.hours.from_now.iso8601
      }
    end
  end

  def create
    token = params[:vote_token]
    token_data = session[:vote_tokens]&.[](token)

    @vote = current_user.votes.build(vote_params)

    @vote.loser_id = @projects.find { |p| p.id != @vote.winner_id }.id if @projects.size == 2

    unless @vote.authorized_with_token?(token_data)
      redirect_to new_vote_path, alert: "Vote validation failed"
      return
    end

    if @vote.save
      session[:vote_tokens].delete(token)

      redirect_to new_vote_path, notice: "Vote Submitted!"
    else
      redirect_to new_vote_path, alert: @vote.errors.full_messages.join(", ")
    end
  end

  def locked
    @projects_count = Project.joins(:ship_certifications, :devlogs)
                    .where(ship_certifications: { judgement: :approved })
                    .group("projects.id")
                    .having("SUM(COALESCE(devlogs.seconds_coded, 0)) > ?", 10 * 3600)
                    .count
                    .keys
                    .size
  end

  private

  def redirect_to_locked
    redirect_to locked_votes_path
  end


  def check_identity_verification
    return if current_user&.identity_vault_id.present? && current_user.verification_status != :ineligible

    redirect_to campfire_path, alert: "Please verify your identity to access this page."
  end

  def set_projects
    voted_winner_ids = current_user.votes.pluck(:winner_id)
    voted_loser_ids = current_user.votes.pluck(:loser_id)
    voted_project_ids = voted_winner_ids + voted_loser_ids

    # TODO: Make sure to check for is_shipped: true before launch
    eligible_user_ids = Project
                         .where.not(id: voted_project_ids)
                         .where.not(user_id: current_user.id)
                         .distinct
                         .pluck(:user_id)
                         .shuffle
                         .first(2)

    if eligible_user_ids.size < 2
      @projects = []
      return
    end

    @projects = eligible_user_ids.map do |user_id|
      Project
        .where.not(id: voted_project_ids)
        .where(user_id: user_id)
        .order("RANDOM()")
        .first
    end.compact
  end

  def vote_params
    params.expect(vote: %i[winner_id explanation
                           winner_demo_opened winner_readme_opened winner_repo_opened
                           loser_demo_opened loser_readme_opened loser_repo_opened
                           time_spent_voting_ms music_played])
  end
end
