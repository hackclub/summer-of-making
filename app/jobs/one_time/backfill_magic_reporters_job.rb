class OneTime::BackfillMagicReportersJob < ApplicationJob
  queue_as :default

  def perform(args)
    projects = Project
                 .magical # magicked_at is not nil
                 .where(magic_reporter: nil) # no reporter already
                 .joins(:versions) # bring in versions
                 .where("(versions.object_changes::jsonb) ? 'magicked_at'") # but only versions changing magicked_at
                 .select("projects.*, versions.whodunnit as magic_reporter_whodunnit") # and pluck the responsible user

    projects.each do |project|
      next unless project.magic_reporter_whodunnit

      project.update!(magic_reporter_id: project.magic_reporter_whodunnit&.to_i)
    end
  end
end
