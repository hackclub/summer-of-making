# frozen_string_literal: true

# == Schema Information
#
# Table name: stonk_ticklers
#
#  id         :bigint           not null, primary key
#  tickler    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :bigint           not null
#
# Indexes
#
#  index_stonk_ticklers_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id) ON DELETE => cascade
#
require "openai"

class StonkTickler < ApplicationRecord
  belongs_to :project

  after_initialize :generate_tickler, if: -> { new_record? && tickler.blank? && project.present? }

  private

  def generate_tickler
    OpenAI.configure { |c| c.access_token = ENV.fetch("OPENAI_KEY") }
    client = OpenAI::Client.new

    response = client.responses.create(parameters: {
                                         model: "gpt-4.1",
                                         input: [
                                           {
                                             role: "developer",
                                             content: [
                                               {
                                                 type: "input_text",
                                                 text: "Summarise the following project title into a fictional 3-4 letter stock ticker. It should be in capitals. Respond ONLY with the ticker."
                                               }
                                             ]
                                           },
                                           {
                                             role: "user",
                                             content: [
                                               {
                                                 type: "input_text",
                                                 text: project.title
                                               }
                                             ]
                                           }
                                         ],
                                         text: {
                                           format: {
                                             type: "text"
                                           }
                                         },
                                         tools: [],
                                         store: false
                                       })

    self.tickler = response.dig("output", 0, "content", 0, "text").strip
  end
end
