module MapHelper
  def placeable_projects_message(count)
    return "No projects available to place. Ship a project first to add it to the map." if count.zero?

    "You can place #{pluralize(count, "project")}. Click a project below to select it, then click on the map to place it, or drag it directly."
  end
end
