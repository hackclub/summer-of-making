class User::UpdateBadgeCounterCachesJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    User.find_each do |user|
      user.update_cached_badges!
    end
  end
end
