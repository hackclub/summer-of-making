# frozen_string_literal: true

class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_voting_not_paused, only: %i[new create]
  before_action :set_projects, only: %i[new]
  before_action :check_identity_verification
  before_action :set_tracking, only: %i[track_demo track_repo]

  def new
    @vote = Vote.new
    @user_vote_count = current_user.votes.active.count
  end

  def create
    if TurnstileService.enabled?
      token = params[:"cf-turnstile-response"] || params[:cf_turnstile_response] || params.dig(:vote, :cf_turnstile_response)
      verification = TurnstileService.verify(token, remote_ip: request.remote_ip)
      unless verification[:success]
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "turnstile-error",
              ActionController::Base.helpers.content_tag(:div, "Turnstile verification failed. Please try again.", class: "text-vintage-red text-sm mt-2")
            ), status: :unprocessable_entity
          end
          format.html do
            redirect_to new_vote_path, alert: "Turnstile verification failed. Please try again."
          end
        end
        return
      end
    end

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

    # we should have done this from the start but it's time when this is excuted - started_at
    time_spt_ms = nil
    if verification_result[:valid]
      payload = verification_result[:payload]
      if payload && payload["timestamp"].present?
        begin
          started_at = Time.at(payload["timestamp"].to_i)
          time_spt_ms = ((Time.current - started_at) * 1000).to_i.clamp(0, 86_400_000)
        rescue StandardError
          time_spt_ms = nil
        end
      end
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
    @vote.time_spent_voting_ms = time_spt_ms

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
      begin
        pair_key = "#{@vote.ship_event_1_id}-#{@vote.ship_event_2_id}"
        clicks = session.dig(:voting_clicks, pair_key)
        if clicks.present?
          @vote.update_columns(
            project_1_demo_opened: clicks["project_1_demo_opened"],
            project_1_repo_opened: clicks["project_1_repo_opened"],
            project_2_demo_opened: clicks["project_2_demo_opened"],
            project_2_repo_opened: clicks["project_2_repo_opened"]
          )
          session[:voting_clicks].delete(pair_key)
        end
      rescue StandardError => e
        Rails.logger.warn("Failed to apply voting click analytics: #{e.message}")
      end
      current_user.advance_vote_queue!
      session.delete(:current_vote_signature)

      begin
        @vote.reload
      rescue StandardError
      end

      if @vote.status == "invalid"
        flash[:vote_rejected] = true
        redirect_to new_vote_path
      else
        vote_result = if @vote.winning_project_id.nil?
                       "Tie vote submitted!"
        else
                       "Vote submitted!"
        end

        redirect_to new_vote_path, notice: vote_result
      end
    else
      redirect_to new_vote_path, alert: @vote.errors.full_messages.join(", ")
    end
  end

  def track_demo
    track_and_redirect!("demo")
  end

  def track_repo
    track_and_redirect!("repo")
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

  def ensure_voting_not_paused
    if defined?(Flipper)
      if Flipper.enabled?(:lock_voting, current_user)
        redirect_to locked_votes_path, alert: "Your voting access has been temporarily disabled due to too many low-quality votes." and return
      end
      if Flipper.enabled?(:voting_paused)
        redirect_to locked_votes_path, alert: "Voting is temporarily paused. Please try again later." and return
      end
    end
  end

  def set_tracking
    position = params[:position].to_i
    unless [ 1, 2 ].include?(position)
      redirect_to new_vote_path, alert: "Invalid link" and return
    end

    queue = current_user.user_vote_queue
    ship_events = queue&.current_ship_events || []
    if ship_events.size != 2
      redirect_to new_vote_path, alert: "Voting pair unavailable" and return
    end

    signature = session[:current_vote_signature]
    unless signature.present?
      redirect_to new_vote_path, alert: "Missing signature" and return
    end
    verification = VoteSignatureService.verify_signature_with_ship_events(
      signature,
      ship_events[0].id,
      ship_events[1].id,
      current_user.id
    )
    unless verification[:valid]
      redirect_to new_vote_path, alert: "Invalid or expired link" and return
    end

    @project_index = position
    @project = ship_events[position - 1].project
  end

  def record_voting_click_for_current_pair!(link_type, project_index)
    return unless current_user&.user_vote_queue

    ship_events = current_user.user_vote_queue.current_ship_events
    return if ship_events.size != 2

    se_ids = [ ship_events[0].id, ship_events[1].id ].sort
    pair_key = "#{se_ids[0]}-#{se_ids[1]}"
    session[:voting_clicks] ||= {}
    session[:voting_clicks][pair_key] ||= {
      "project_1_demo_opened" => false,
      "project_1_repo_opened" => false,
      "project_2_demo_opened" => false,
      "project_2_repo_opened" => false
    }

    field = "project_#{project_index}_#{link_type}_opened"
    session[:voting_clicks][pair_key][field] = true
  end

  def track_and_redirect!(link_type)
    authorize @project, :show?
    record_voting_click_for_current_pair!(link_type, @project_index)
    target_url = case link_type
    when "demo" then @project.demo_link
    when "repo" then @project.repo_link
    else nil
    end
    redirect_to(target_url.presence || project_path(@project), allow_other_host: true)
  end

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
      queue.with_lock do
        if queue.queue_exhausted?
          queue.refill_queue!(UserVoteQueue::QUEUE_SIZE)
        end
      end
    end

    Rails.logger.info("bc js work #{@vote_queue.inspect}")

    @projects = @vote_queue.current_projects

    if @projects.size < 2
      @projects = []
      return
    end

    @ship_events = @vote_queue.current_ship_events

    # what in the vibe code did rowan do here before :skulk:
    @project_ai_used = {}
    @projects.each do |project|
      ai_used = if project.respond_to?(:ai_used?)
        project.ai_used?
      end
      @project_ai_used[project.id] = ai_used
    end

    @vote_signature = @vote_queue.generate_current_signature
    session[:current_vote_signature] = @vote_signature
  end

  def vote_params
    params.expect(vote: %i[winning_project_id explanation
                           ship_event_1_id ship_event_2_id signature cf_turnstile_response])
  end
end
