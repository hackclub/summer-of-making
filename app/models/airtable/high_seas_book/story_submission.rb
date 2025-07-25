# == Schema Information
#
# Table name: airtable_high_seas_book_story_submissions
#
#  id              :bigint           not null, primary key
#  airtable_fields :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  airtable_id     :string
#
class Airtable::HighSeasBook::StorySubmission < ApplicationRecord
  # jsonb: airtable_fields
  # string: airtable_id

  include BackedByAirtable
  has_airtable_attachment "Photos (Optional)", :photo
  backed_by_filter "{Show in Summer of Making}"

  class AirtableRecord < Norairrecord::Table
    self.base_key = "appKexHWHYYVY1GFW"
    self.table_name = "tblGUy12HSqCXveg2"
    self.api_key = ENV["HIGHSEAS_AIRTABLE_KEY"]
  end

  def testimonial
    airtable_fields["What's one way High Seas had a positive impact on your life?"]
  end

  def webtestimonial
    airtable_fields["WebTestimony"]
  end
end
