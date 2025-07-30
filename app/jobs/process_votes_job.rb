# frozen_string_literal: true

class ProcessVotesJob < ApplicationJob
  include UniqueJob
  queue_as :default

  BATCH_SIZE = 20

  def perform
    votes = Vote.where(processed_at: nil).order(:id).limit(BATCH_SIZE)
    return if votes.empty?

    votes.each do |vote|
      result = analyze_vote_with_ai(vote)
      vote.update!(processed_at: Time.current, ai_feedback: result[:reason])
    end

    self.class.perform_unique if Vote.where(processed_at: nil).exists?
  end

  private

  def analyze_vote_with_ai(vote)
    prompt = <<~PROMPT
      Analyze the following vote for quality. Is it likely written by AI (look for em dashes or generic language)? Does it relate to the two projects below? Reply with a short reason if flagged, or 'OK' if not./no_think

      Vote: #{vote.text}
      Project 1: #{vote.project_1&.name}
      Project 2: #{vote.project_2&.name}
    PROMPT

    response = Faraday.post("https://ai.hackclub.com/chat/completions", { prompt: prompt }.to_json, "Content-Type" => "application/json")
    body = JSON.parse(response.body)
    feedback = body["choices"]&.first&.dig("message", "content") || "No response"
    flagged = feedback != "OK"
    { flagged: flagged, reason: feedback }
  rescue => e
    { flagged: false, reason: "AI error: #{e.message}" }
  end
end
