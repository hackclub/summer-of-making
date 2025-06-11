# frozen_string_literal: true

class TimerSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, except: [ :global_active ]
  before_action :set_timer_session, only: %i[update show destroy]
  before_action :ensure_timer_not_stopped, only: %i[update destroy]

  def show
    if @timer_session
      render json: {
        id: @timer_session.id,
        started_at: @timer_session.started_at,
        last_paused_at: @timer_session.last_paused_at,
        accumulated_paused: @timer_session.accumulated_paused,
        status: @timer_session.status,
        net_time: @timer_session.net_time
      }
    else
      render json: { error: "No active timer session found" }, status: :not_found
    end
  end

  def create
    render json: { error: "Timer sessions are currently disabled" }, status: :service_unavailable
    return

    active_session = TimerSession.where(user: current_user, status: %i[running paused]).first

    if active_session
      project = active_session.project
      error_message = "You already have an active timer session for the project '#{project.title}'. Please finish or stop that session first."
      redirect_to project_path(@project), alert: error_message
      return
    end

    @timer_session = @project.timer_sessions.build(
      user: current_user,
      started_at: Time.current,
      status: :running
    )

    if @timer_session.save
      # show indicator
      Turbo::StreamsChannel.broadcast_replace_to(
        current_user,
        "timer_indicator",
        target: "timer-indicator",
        partial: "shared/timer_indicator_content",
        locals: { active_timer_session: @timer_session }
      )

      render json: {
        id: @timer_session.id,
        started_at: @timer_session.started_at,
        status: @timer_session.status
      }
    else
      error_message = @timer_session.errors.full_messages.join(", ")
      redirect_to project_path(@project), alert: error_message
    end
  end

  def update
    case params[:action_type]
    when "pause"
      @timer_session.update(last_paused_at: Time.current, status: :paused)
    when "resume"
      paused_duration = Time.current - @timer_session.last_paused_at
      new_accumulated = @timer_session.accumulated_paused + paused_duration.to_i
      @timer_session.update(accumulated_paused: new_accumulated, status: :running)
    when "stop"
      end_time = Time.current

      if @timer_session.paused? && @timer_session.last_paused_at.present?
        paused_duration = end_time - @timer_session.last_paused_at
        @timer_session.accumulated_paused += paused_duration.to_i
      end

      elapsed = end_time - @timer_session.started_at
      net_time = elapsed - @timer_session.accumulated_paused

      if net_time.to_i < TimerSession::MINIMUM_DURATION
        @timer_session.errors.add(:base, "Timer sessions must be at least 5 minutes long")
      else
        @timer_session.update(stopped_at: end_time, net_time: net_time.to_i, status: :stopped)

        # hide indicator
        Turbo::StreamsChannel.broadcast_replace_to(
          current_user,
          "timer_indicator",
          target: "timer-indicator",
          partial: "shared/timer_indicator_content",
          locals: { active_timer_session: nil }
        )
      end
    end

    if @timer_session.errors.any?
      render json: { error: @timer_session.errors.full_messages.join(", ") }, status: :unprocessable_entity
    else
      render json: {
        id: @timer_session.id,
        status: @timer_session.status,
        net_time: @timer_session.net_time,
        accumulated_paused: @timer_session.accumulated_paused
      }
    end
  end

  def active
    @timer_session = @project.timer_sessions.where(user: current_user,
                                                   status: %i[
                                                     running paused
                                                   ]).order(created_at: :desc).first

    if @timer_session
      render json: {
        id: @timer_session.id,
        started_at: @timer_session.started_at,
        last_paused_at: @timer_session.last_paused_at,
        accumulated_paused: @timer_session.accumulated_paused,
        status: @timer_session.status
      }
    else
      render json: { active: false }, status: :ok
    end
  end

  def global_active
    @timer_session = TimerSession.where(user: current_user,
                                        status: %i[running
                                                   paused]).order(created_at: :desc).first

    if @timer_session
      render json: {
        id: @timer_session.id,
        project_id: @timer_session.project_id,
        started_at: @timer_session.started_at,
        last_paused_at: @timer_session.last_paused_at,
        accumulated_paused: @timer_session.accumulated_paused,
        status: @timer_session.status
      }
    else
      render json: { active: false }, status: :ok
    end
  end

  def destroy
    if @timer_session.user == current_user
      if @timer_session.destroy
        # hide indicator
        Turbo::StreamsChannel.broadcast_replace_to(
          current_user,
          "timer_indicator",
          target: "timer-indicator",
          partial: "shared/timer_indicator_content",
          locals: { active_timer_session: nil }
        )

        render json: { success: true }, status: :ok
      else
        render json: { error: @timer_session.errors.full_messages.join(", ") }, status: :unprocessable_entity
      end
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_timer_session
    @timer_session = @project.timer_sessions.find(params[:id])
  end

  def ensure_timer_not_stopped
    return unless @timer_session.stopped?

    render json: { error: "Stopped timer sessions cannot be modified" }, status: :unprocessable_entity
    false
  end
end
