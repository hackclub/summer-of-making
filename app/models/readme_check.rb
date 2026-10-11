# frozen_string_literal: true

# == Schema Information
#
# Table name: readme_checks
#
#  id          :bigint           not null, primary key
#  content     :string
#  decision    :integer
#  readme_link :string
#  reason      :string
#  status      :integer          default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#
# Indexes
#
#  index_readme_checks_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id) ON DELETE => cascade
#
class ReadmeCheck < ApplicationRecord
  after_create :get_readme_content

  belongs_to :project

  enum :status, { pending: 0, success: 1, failure: 2 }
  enum :decision, { templated: 0, ai_generated: 1, specific: 2, missing: 3 }

  private

  def get_readme_content
    return unless project.readme_link.present?
    update(readme_link: project.readme_link)

    begin
      response = Faraday.get(readme_link)

      if response.success?
        self.update(status: :pending, content: response.body)
        enqueue_check
      else
        self.update(status: :failure, reason: "README not found at link (HTTP #{response.status})")
      end
    rescue StandardError => e
      self.update(status: :failure, reason: "Failed to fetch README: #{e.message}")
    end
  end

  def enqueue_check
    Mole::ReadmeCheckJob.perform_later(self.id)
  end

  def perform_check
    prompt = <<~PROMPT
      Review this README content and classify it based on whether you can understand what the project actually does.

      Respond with one of:
      - `TEMPLATED: reason` - You cannot tell what this project does (generic templates, boilerplate, single headers, create-react-app defaults, etc.)
      - `AI_GENERATED: reason` - Content appears to be AI-generated#{'  '}
      - `SPECIFIC: reason` - You can understand what this specific project does from the description
      - `MISSING: reason` - The README is missing a description of what the project does or is empty

      The key question: Can you tell what this project is and what it does from reading this README?

      Note: Just having a project name is not enough for SPECIFIC - there needs to be actual description of functionality.

      No yapping. Just respond back in the correct format. Also, don't include any formatting or markdown, only use plain text.

      README content:
      #{content.split("\n").map { |line| "> #{line}" }.join("\n")}
    PROMPT

    approved_outputs = %w[TEMPLATED AI_GENERATED SPECIFIC MISSING]
    result = GroqService.call(prompt)

    result.split(":").first.strip.upcase.tap do |decision|
      if approved_outputs.include?(decision)
        result_reason = result.split(":")[1..-1].join(":").strip if result.include?(":")

        case decision.downcase.to_sym
        when :templated
          self.update(status: :success, decision: :templated, reason: result_reason || "The README is a generic template.")
        when :ai_generated
          self.update(status: :success, decision: :ai_generated, reason: result_reason || "The README looks pretty generated and hard to read.")
        when :specific
          self.update(status: :success, decision: :specific, reason: result_reason || "The README looks good!")
        when :missing
          self.update(status: :success, decision: :missing, reason: result_reason || "The README is missing or empty.")
        end
      else
        raise GroqService::InferenceError, "Unexpected decision format: #{decision}"
      end
    end

  rescue GroqService::InferenceError => e
    self.update(status: :failure, reason: e.message)
  end
end
