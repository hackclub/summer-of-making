# frozen_string_literal: true

# == Schema Information
#
# Table name: readme_checks
#
#  id               :bigint           not null, primary key
#  content          :string
#  decision         :integer
#  decision_message :string
#  readme_link      :string
#  reason           :string
#  status           :integer          default("pending"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  project_id       :bigint           not null
#
# Indexes
#
#  index_readme_checks_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#
class ReadmeCheck < ApplicationRecord
  after_create :get_readme_content

  belongs_to :project

  enum :status, { pending: 0, success: 1, failure: 2 }
  enum :decision, {
    templated: 0, # "Welcome to the React / Next.js / etc. starter template!"
    ai_generated: 1, # this is ai slop
    specific: 2, # this is a good readme with a specific description of what it does
    missing: 3 # link not working
  }

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

  def perform_link_check
    # check the link...
    return false unless readme_link.present?

    # check the link works...
    req = Faraday.get(readme_link)
    return false unless req.success?

    # check the link is a markdown/txt file...
    is_raw_link = [ "text/markdown", "text/plain" ].include? req.headers["content-type"]
    false unless is_raw_link || attempt_to_find_raw_link
  end

  def attempt_to_find_raw_link
    # Most links should already be fixed by our one-time jobs
    # This is just a simple fallback for any remaining edge cases
    return false unless readme_link.present?

    # Quick conversion for any remaining blob URLs
    if readme_link.include?("github.com") && readme_link.include?("/blob/")
      converted_link = readme_link.gsub(%r{https://github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'https://raw.githubusercontent.com/\1/\2/\3')

      if converted_link != readme_link
        self.update(readme_link: converted_link)

        # Test the converted link
        req = Faraday.get(converted_link)
        return req.success? && [ "text/markdown", "text/plain" ].include?(req.headers["content-type"])
      end
    end

    false
  end

  def perform_content_check
    # Pre-check for obvious cases before using AI
    if content_is_missing_or_minimal?
      return handle_missing_content
    end

    prompt = <<~PROMPT
      Review this README content and classify it based on whether you can understand what the project actually does.

      Respond with one of:
      - `TEMPLATED: reason` - You cannot tell what this project does (generic templates, boilerplate, single headers, create-react-app defaults, etc.)
      - `AI_GENERATED: reason` - Content appears to be AI-generated. Things like "clone https://github.com/username/repo.git" or heavy use of emoji is a good indicator. Also talking a lot about generic things.
      - `SPECIFIC: reason` - You can understand what this project specifically does from the description
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
          self.update(
            status: :success,
            decision: :templated,
            reason: result_reason || "The README is a generic template.",
            decision_message: FlavorTextService.generate_mole_message_for_decision(:templated, result_reason)
          )
        when :ai_generated
          self.update(
            status: :success,
            decision: :ai_generated,
            reason: result_reason || "The README looks pretty generated and hard to read.",
            decision_message: FlavorTextService.generate_mole_message_for_decision(:ai_generated, result_reason)
          )
        when :specific
          self.update(
            status: :success,
            decision: :specific,
            reason: result_reason || "The README looks good!",
            decision_message: FlavorTextService.generate_mole_message_for_decision(:specific, result_reason)
          )
        when :missing
          self.update(
            status: :success,
            decision: :missing,
            reason: result_reason || "The README is missing or empty.",
            decision_message: FlavorTextService.generate_mole_message_for_decision(:missing, result_reason)
          )
        end
      else
        raise GroqService::InferenceError, "Unexpected decision format: #{decision}"
      end
    end

  rescue GroqService::InferenceError => e
    self.update(status: :failure, reason: e.message)
  end

  private

  def content_is_missing_or_minimal?
    return true if content.blank?

    begin
      # Ensure we have valid UTF-8 content
      safe_content = content.dup
      unless safe_content.valid_encoding?
        safe_content = safe_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
      end

      # Split into non-empty lines
      lines = safe_content.strip.split("\n").reject(&:blank?)
      return true if lines.empty?

      # Check if it's just a single heading (h1-h6) with no other content
      if lines.length == 1 && lines.first.strip.match?(/^#+\s+.+$/)
        return true
      end

      # If we have multiple lines, check if there's any substantial non-header content
      if lines.length > 1
        non_header_lines = lines.reject { |line| line.strip.match?(/^#+\s+.+$/) }
        if non_header_lines.any? { |line| line.strip.length > 10 }
          return false # Has substantial content
        end
      end

      # Check if total text content is extremely short (just a few words)
      text_only = safe_content.gsub(/[#*`_\[\]()!]/, "").gsub(/\s+/, " ").strip
      return true if text_only.length < 8

      false
    rescue Encoding::CompatibilityError, ArgumentError => e
      Rails.logger.warn "Encoding error in content_is_missing_or_minimal?: #{e.message}"
      # If we can't process the content due to encoding issues, assume it has content
      false
    end
  end

  def handle_missing_content
    self.update(
      status: :success,
      decision: :missing,
      reason: "README content is missing, empty, or contains only a title.",
      decision_message: FlavorTextService.generate_mole_message_for_decision(:missing)
    )
  end
end
