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
    # Get projects that haven't been voted on by current user
    voted_ship_event_ids = current_user.votes
                                      .joins(vote_changes: { project: :ship_events })
                                      .distinct
                                      .pluck("ship_events.id")

    projects_with_latest_ship = Project
                                  .joins(:ship_events)
                                  .joins(:ship_certifications)
                                  .joins(:devlogs)
                                  .includes(ship_events: :payouts)
                                  .where(ship_certifications: { judgement: :approved })
                                  .where.not(user_id: current_user.id)
                                  .where(
                                    ship_events: {
                                      id: ShipEvent.select("MAX(ship_events.id)")
                                                  .where("ship_events.project_id = projects.id")
                                                  .group("ship_events.project_id")
                                                  .where.not(id: voted_ship_event_ids)
                                    }
                                  )
                                  .group("projects.id")
                                  .having("COUNT(devlogs.id) > 0")
                                  .distinct

    if projects_with_latest_ship.count.size < 2
      @projects = []
      return
    end

    eligible_projects = projects_with_latest_ship.to_a

    latest_ship_event_ids = eligible_projects.map { |project|
      project.ship_events.max_by(&:created_at).id
    }

    total_times_by_ship_event = Devlog
      .joins("INNER JOIN ship_events ON devlogs.project_id = ship_events.project_id")
      .where(ship_events: { id: latest_ship_event_ids })
      .where("devlogs.created_at <= ship_events.created_at")
      .group("ship_events.id")
      .sum(:duration_seconds)

    projects_with_time = eligible_projects.map do |project|
      latest_ship_event = project.ship_events.max_by(&:created_at)
      total_time_seconds = total_times_by_ship_event[latest_ship_event.id] || 0
      is_paid = latest_ship_event.payouts.any?

      {
        project: project,
        total_time: total_time_seconds,
        ship_event: latest_ship_event,
        is_paid: is_paid,
        ship_date: latest_ship_event.created_at
      }
    end

    # sort by ship date – disabled until genesis
    projects_with_time.sort_by! { |p| p[:ship_date] }

    unpaid_projects = projects_with_time.select { |p| !p[:is_paid] }
    paid_projects = projects_with_time.select { |p| p[:is_paid] }

    # we need at least 1 unpaid project and 1 other project (status doesn't matter)
    if unpaid_projects.empty? || projects_with_time.size < 2
      @projects = []
      return
    end

    selected_projects = []
    selected_project_data = []
    used_user_ids = Set.new
    used_repo_links = Set.new
    max_attempts = 25 # infinite loop!

    attempts = 0
    # TODO: change to weighted_sample after genesis
    while selected_projects.size < 2 && attempts < max_attempts
      attempts += 1

      # pick a random unpaid project first
      if selected_projects.empty?
        available_unpaid = unpaid_projects.select { |p| !used_user_ids.include?(p[:project].user_id) && !used_repo_links.include?(p[:project].repo_link) }
        first_project_data = weighted_sample(available_unpaid)
        next unless first_project_data

        selected_projects << first_project_data[:project]
        selected_project_data << first_project_data
        used_user_ids << first_project_data[:project].user_id
        used_repo_links << first_project_data[:project].repo_link if first_project_data[:project].repo_link.present?
        first_time = first_project_data[:total_time]

        # find projects within the constraints (set to 30%)
        min_time = first_time * 0.7
        max_time = first_time * 1.3

        compatible_projects = projects_with_time.select do |p|
          !used_user_ids.include?(p[:project].user_id) &&
          !used_repo_links.include?(p[:project].repo_link) &&
          p[:total_time] >= min_time &&
          p[:total_time] <= max_time
        end

        if compatible_projects.any?
          second_project_data = weighted_sample(compatible_projects)
          selected_projects << second_project_data[:project]
          selected_project_data << second_project_data
          used_user_ids << second_project_data[:project].user_id
          used_repo_links << second_project_data[:project].repo_link if second_project_data[:project].repo_link.present?
        else
          selected_projects.clear
          selected_project_data.clear
          used_user_ids.clear
          used_repo_links.clear
        end
      end
    end

    # js getting smtth if after 25 attemps we have nothing
    if selected_projects.size < 2 && unpaid_projects.any?
      first_project_data = weighted_sample(unpaid_projects)
      remaining_projects = projects_with_time.reject { |p|
        p[:project].user_id == first_project_data[:project].user_id ||
        (p[:project].repo_link.present? && p[:project].repo_link == first_project_data[:project].repo_link)
      }

      if remaining_projects.any?
        second_project_data = weighted_sample(remaining_projects)
        selected_projects = [ first_project_data[:project], second_project_data[:project] ]
        selected_project_data = [ first_project_data, second_project_data ]
      end
    end

    if selected_projects.size < 2
      @projects = []
      return
    end

    # load what we need
    selected_project_ids = selected_projects.map(&:id)
    @projects = Project
                .includes(:banner_attachment,
                          :ship_certifications,
                          ship_events: :payouts,
                          devlogs: [ :user, :file_attachment ])
                .where(id: selected_project_ids)
                .index_by(&:id)
                .values_at(*selected_project_ids)

    @ship_events = selected_project_data.map { |data| data[:ship_event] }

    @project_ai_used = {}
    @projects.each do |project|
      ai_used = if project.respond_to?(:ai_used?)
        project.ai_used?
      elsif project.ship_certifications.loaded? && project.ship_certifications.any? { |cert| cert.respond_to?(:ai_used?) }
        latest_cert = project.ship_certifications.max_by(&:created_at)
        latest_cert&.ai_used? || false
      else
        false
      end
      @project_ai_used[project.id] = ai_used
    end

    if @ship_events.size == 2
      @vote_signature = VoteSignatureService.generate_signature(
        @ship_events[0].id,
        @ship_events[1].id,
        current_user.id
      )
    end
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           project_1_demo_opened project_1_repo_opened
                           project_2_demo_opened project_2_repo_opened
                           time_spent_voting_ms music_played
                           ship_event_1_id ship_event_2_id signature])
  end

  # this function is what we used in High seas
  def weighted_sample(projects)
    return nil if projects.empty?
    return projects.first if projects.size == 1

    # Create weights where earlier projects (index 0) have higher weight
    # Weight decreases exponentially: first project gets weight 1.0, second gets 0.95, third gets 0.90, etc.
    weights = projects.map.with_index { |_, index| 0.95 ** index }
    total_weight = weights.sum

    # Generate random number between 0 and total_weight
    random = rand * total_weight

    # Find the project corresponding to this random weight
    cumulative_weight = 0
    projects.each_with_index do |project, index|
      cumulative_weight += weights[index]
      return project if random <= cumulative_weight
    end

    # Fallback (should never reach here)
    projects.first
  end
end
