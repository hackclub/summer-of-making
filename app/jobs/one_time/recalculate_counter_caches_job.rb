class OneTime::RecalculateCounterCachesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting counter cache recalculation..."

    recalculate_project_counters
    recalculate_user_counters

    Rails.logger.info "Counter cache recalculation completed!"
  end

  private

  def recalculate_project_counters
    Rails.logger.info "Recalculating project counter caches..."

    i = 0
    Project.unscoped.in_batches(of: 1000) do |batch|
      Rails.logger.info "Processing projects batch #{i += 1}..."

      batch.update_all(
        "ship_events_count = (SELECT COUNT(*) FROM ship_events WHERE ship_events.project_id = projects.id),
         followers_count = (SELECT COUNT(*) FROM project_follows WHERE project_follows.project_id = projects.id),
         devlogs_count = (SELECT COUNT(*) FROM devlogs WHERE devlogs.project_id = projects.id)"
      )
    end
  end

  def recalculate_user_counters
    Rails.logger.info "Recalculating user counter caches..."

    i = 0
    User.unscoped.in_batches(of: 1000) do |batch|
      Rails.logger.info "Processing users batch #{i += 1}..."

      batch.update_all(
        "projects_count = (SELECT COUNT(*) FROM projects WHERE projects.user_id = users.id AND projects.is_deleted = false),
         devlogs_count = (SELECT COUNT(*) FROM devlogs WHERE devlogs.user_id = users.id),
         votes_count = (SELECT COUNT(*) FROM votes WHERE votes.user_id = users.id),
         ship_events_count = (SELECT COUNT(*) FROM ship_events INNER JOIN projects ON ship_events.project_id = projects.id WHERE projects.user_id = users.id AND projects.is_deleted = false)"
      )
    end
  end
end
