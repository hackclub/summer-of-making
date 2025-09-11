# This is based on https://thoughtbot.com/blog/using-the-presenter-pattern-in-ruby-on-rails
# It's an antipattern to pull out a new abstraction like this, but I'm doing it
# in this case because the event has 20 days left.

# I strongly encourage not doing this for other cases of messy code,
# particularly if the event gets extended again. - @msw
class ProjectMapPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::DateHelper
  include ApplicationHelper

  def initialize(project)
    @project = project
  end

  def to_h
    {
      id: @project.id,
      x: @project.x,
      y: @project.y,
      title: @project.title,
      user_id: @project.user_id,
      devlogs_count: @project.devlogs_count,
      total_time_spent: format_seconds(@project.total_seconds_coded),
      project_path: project_path(@project),
      user: user_data
    }.compact
  end

  def self.collection(projects)
    projects.map { |project| new(project).to_h }
  end

  private

  def user_data
    {
      display_name: @project.user.display_name,
      avatar: avatar_url,
      favorite_color: @project.user.user_profile&.balloon_color
    }
  end

  def avatar_url
    Rails.application.routes.url_helpers.url_for(@project.user.avatar)
  end
end
