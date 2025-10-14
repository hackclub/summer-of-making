class ShowcaseController < ApplicationController
  before_action :authenticate_user!

  def new
    @project = Showcase::Matchmaker.new(user: current_user).pick

    if @project.nil?
      redirect_to explore_path, alert: "No eligible projects available right now." and return
    end

    ActiveRecord::Associations::Preloader
      .new(records: [ @project ], associations: [ { banner_attachment: :blob } ])
      .call

    @devlogs = Devlog.where(project_id: @project.id)
                     .includes({ user: :user_badges }, { file_attachment: :blob })
                     .order(:created_at)

    @grade_labels = VoteMf::GRADE_LABELS
    @criteria = VoteMf::CRITERIA
    @vote_mf = VoteMf.new(project: @project, voter: current_user)

    session[:showcase_started_at] = Time.current.to_i
  end

  def create
    # yes, this is indeed vibecoded. I do not have motivation to work on SoM's codebase. check out battlemage tho. that said, i wrote the matchmakign service and the models by hand
    @project = Project.find(params.require(:project_id))
    if @project.user_id == current_user.id
      redirect_to showcase_path, alert: "You cannot vote on your own project." and return
    end

    raw_ballot = params.require(:vote_mf).permit(ballot: {})[:ballot] || {}

    time_spt_ms = nil
    if session[:showcase_started_at].present?
      begin
        started_at = Time.at(session[:showcase_started_at].to_i)
        time_spt_ms = ((Time.current - started_at) * 1000).to_i.clamp(0, 86_400_000)
      rescue StandardError
        time_spt_ms = nil
      end
    end

    @vote_mf = VoteMf.new(
      project: @project,
      voter: current_user,
      ballot: raw_ballot,
      time_spent_voting_ms: time_spt_ms
    )

    if @vote_mf.save
      session.delete(:showcase_started_at)
      redirect_to showcase_path, notice: "Thanks! Your vote was recorded."
    else
      ActiveRecord::Associations::Preloader
        .new(records: [ @project ], associations: [ { banner_attachment: :blob } ])
        .call
      @devlogs = Devlog.where(project_id: @project.id)
                       .includes({ user: :user_badges }, { file_attachment: :blob })
                       .order(:created_at)
      @grade_labels = VoteMf::GRADE_LABELS
      @criteria = VoteMf::CRITERIA
      flash.now[:alert] = @vote_mf.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end
end
