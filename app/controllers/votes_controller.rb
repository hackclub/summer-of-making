# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_projects, only: %i[new]
  before_action :check_identity_verification

  def new
    @vote = Vote.new
    @user_vote_count = current_user.votes.count
  end

  def create
    ship_event_1_id = params[:vote][:ship_event_1_id]&.to_i
    ship_event_2_id = params[:vote][:ship_event_2_id]&.to_i
    signature = params[:vote][:signature]

    unless ship_event_1_id && ship_event_2_id && signature.present?
      redirect_to new_vote_path, alert: "Missing vote information"
      return
    end

    # normalizing the order of the ship events because (5,10) and (10,5) are the same
    verification_result = VoteSignatureService.verify_signature_with_ship_events(
      signature, ship_event_1_id, ship_event_2_id, current_user.id
    )

    unless verification_result[:valid]
      redirect_to new_vote_path, alert: "Invalid vote submission: #{verification_result[:error]}"
      return
    end

    ship_events = ShipEvent.where(id: [ ship_event_1_id, ship_event_2_id ]).includes(:project)
    if ship_events.size != 2
      redirect_to new_vote_path, alert: "Invalid ship events selected"
      return
    end

    @ship_events = ship_events.to_a
    @projects = @ship_events.map(&:project)

    @vote = current_user.votes.build(vote_params.except(:ship_event_1_id, :ship_event_2_id, :signature))
    @vote.ship_event_1_id = ship_event_1_id
    @vote.ship_event_2_id = ship_event_2_id

    # Backward compatibility
    @vote.project_1_id = @ship_events[0].project.id
    @vote.project_2_id = @ship_events[1].project.id
    # Handle tie case
    @vote.winning_project_id = nil if @vote.winning_project_id == "tie"
    # Validate that winning project is one of the two projects (for now, until we remove client-side selection)
    if @vote.winning_project_id.present?
      valid_project_ids = @projects.map(&:id)
      unless valid_project_ids.include?(@vote.winning_project_id.to_i)
        redirect_to new_vote_path, alert: "Invalid project selection"
        return
      end
    end

    if @vote.save
      current_user.advance_vote_queue!

      vote_result = if @vote.winning_project_id.nil?
                     "Tie vote submitted!"
      else
                     "Vote submitted!"
      end

      redirect_to new_vote_path, notice: vote_result
    else
      redirect_to new_vote_path, alert: @vote.errors.full_messages.join(", ")
    end
  end

  def locked
    @approve_projects_count = Project.joins(:ship_certifications)
                                     .where(ship_certifications: { judgement: :approved })
                                     .size
    @full_projects_count = Project.joins(:ship_certifications, :devlogs)
                                  .where(ship_certifications: { judgement: :approved })
                                  .group("projects.id")
                                  .having("SUM(COALESCE(devlogs.duration_seconds, 0)) > ?", 10 * 3600)
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
    @vote_queue = current_user.user_vote_queue || current_user.build_user_vote_queue.tap do |queue|
      queue.save!
      RefillUserVoteQueueJob.perform_now(current_user.id)
    end

    Rails.logger.info("bc js work #{@vote_queue.inspect}")

    @ship_events = @vote_queue.current_ship_events

    if @ship_events.size < 2
      @projects = []
      return
    end

    @projects = @vote_queue.current_projects

    # what in the vibe code did rowan do here before :skulk:
    @project_ai_used = {}
    @projects.each do |project|
      ai_used = if project.respond_to?(:ai_used?)
        project.ai_used?
      end
      @project_ai_used[project.id] = ai_used
    end

    @vote_signature = @vote_queue.generate_current_signature
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           project_1_demo_opened project_1_repo_opened
                           project_2_demo_opened project_2_repo_opened
                           time_spent_voting_ms music_played
                           ship_event_1_id ship_event_2_id signature])
  end
end
