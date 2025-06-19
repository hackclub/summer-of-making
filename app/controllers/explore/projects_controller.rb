class Explore::ProjectsController < ApplicationController
  def index
    @projects = Project.includes(:user, :devlogs, :banner_attachment, devlogs: :file_attachment, user: :hackatime_stat).order(created_at: :asc)
    @pagy, @projects = pagy(@projects, items: 10)
  end
end
