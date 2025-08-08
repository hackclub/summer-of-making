module MapHelper
  include ApplicationHelper

  def project_map_data(projects)
    projects.map do |project|
      {
        id: project.id,
        x: project.x,
        y: project.y,
        title: project.title,
        user_id: project.user_id,
        devlogs_count: project.devlogs_count,
        total_time_spent: format_seconds(project.total_seconds_coded),
        project_path: project_path(project),
        user: {
          display_name: project.user.display_name,
          avatar: url_for(project.user.avatar),
          favorite_color: project.user.user_profile&.balloon_color
        }
      }.compact
    end
  end

  def map_projects_query
    Project.joins(:ship_events).on_map.includes(user: :user_profile).distinct
  end

  def placeable_projects_message(count)
    return "No projects available to place. Ship a project first to add it to the map." if count.zero?

    "You can place #{pluralize(count, "project")}. Click a project below to select it, then click on the map to place it, or drag it directly."
  end
end
