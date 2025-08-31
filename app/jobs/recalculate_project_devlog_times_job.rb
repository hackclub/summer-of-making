# this is job that recals ALL devlogs for a project. it exists for a reason and i don't want to use RecalculateDevlogTimesJob
class RecalculateProjectDevlogTimesJob < ApplicationJob
  queue_as :literally_whenever

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return unless project

    project.devlogs.order(:created_at).find_each do |devlog|
      devlog.recalculate_seconds_coded
    end
  end
end
