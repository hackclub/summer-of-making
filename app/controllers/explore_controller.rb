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
  rescue Pagy::OverflowError
    redirect_to explore_gallery_path
  end
end
