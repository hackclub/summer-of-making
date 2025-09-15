class ExploreController < ApplicationController
  def index
    authorize :explore, :index?

    devlogs = Devlog.for_explore_feed
    @pagy, @recent_devlogs = pagy(devlogs, items: 8)
  rescue Pagy::OverflowError
    redirect_to explore_path
  end

  def following
    authorize :explore, :following?

    devlogs = Devlog.for_user_following(current_user.id)
    @pagy, @recent_devlogs = pagy(devlogs, items: 8)
  rescue Pagy::OverflowError
    redirect_to explore_following_path
  end

  def gallery
    authorize :explore, :gallery?

    projects = Project.for_gallery
    @pagy, @projects = pagy(projects, items: 12)
    @gallery_pagy = @pagy

    if user_signed_in? && @projects.present?
      project_ids = @projects.map(&:id)
      @followed_project_ids = current_user.project_follows.where(project_id: project_ids).pluck(:project_id).to_set
    end

  rescue Pagy::OverflowError
    redirect_to explore_gallery_path
  end
end
