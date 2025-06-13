class PullHighSeasStoriesFromAirtableJob < ApplicationJob
  queue_as :default

  def perform
    Airtable::HighSeasBook::StorySubmission.destructive_pull_all_from_airtable!
  end
end
