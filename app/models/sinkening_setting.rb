# == Schema Information
#
# Table name: sinkening_settings
#
#  id              :bigint           not null, primary key
#  intensity       :float
#  slack_story_url :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class SinkeningSetting < ApplicationRecord
  validates :intensity, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10 }

  def self.current
    first || create!(intensity: 0.3)
  end

  def self.intensity
    self.current.intensity
  end

  def self.set_intensity(value)
    self.current.update!(intensity: value)
  end

  def self.story_url
    self.current.slack_story_url.presence || ENV["SOM_BALLOON_STORY_URL"].presence || "https://hackclub.slack.com/archives/C090B3T9R9R"
  end
end
