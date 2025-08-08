module Balloonable
  extend ActiveSupport::Concern

  included { after_create :inflate_a_balloon }

  def inflate_a_balloon
    ActionCable.server.broadcast "balloons", {
      type: self.class.name,
      href: self.project.present? ? Rails.application.routes.url_helpers.project_url(self.project, only_path: true) : "/",
      color: self.user.user_profile&.balloon_color || %w[#b00b69 #69b00b #d90ba7 #1ffffa].sample,
      tagline: ERB::Util.html_escape(case self
               when Devlog
                 "#{self.user.display_name} posted a devlog on #{self.project.title}"
               when ShipEvent
                 "#{self.user.display_name} shipped #{self.project.title}!!"
               else
                 ""
               end)
    }
  end
end
