class OneTime::ExistingMagicLetterBatchJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Project.pending_magic_letter.find_each do |project|
      Project::MagicHappeningLetterJob.perform_now(project)
    end
  end
end
