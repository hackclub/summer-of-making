class Cache::MapPointsJob < ApplicationJob
  queue_as :literally_whenever

  CACHE_KEY = "map_projects_data"
  CACHE_DURATION = 1.hour

  def perform(force: false)
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
      projects = Project.joins(:ship_events)
                        .on_map
                        .includes(:devlogs, user: :user_profile)
                        .distinct

      ::ProjectMapPresenter.collection(projects)
    end
  end
end
