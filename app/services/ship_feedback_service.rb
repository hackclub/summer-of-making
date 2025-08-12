class ShipFeedbackService
  def initialize(ship_event)
    @ship_event = ship_event
  end

  def generate_feedback
    votes = collect_payout_votes
    return nil if votes.empty?

    explanations = votes.map(&:explanation).join("\n---\n")
    
    prompt = build_feedback_prompt(explanations)
    
    begin
      payload = {
        messages: [{ role: "user", content: prompt }],
        model: "qwen/qwen3-32b",
        reasoning_effort: "default",
        include_reasoning: false,
        temperature: 0.7
      }
      
      response = Faraday.post("https://ai.hackclub.com/chat/completions", payload.to_json, "Content-Type" => "application/json")
      body = JSON.parse(response.body)
      feedback = body["choices"]&.first&.dig("message", "content") || "No response from AI"
      
      if feedback.present?
        @ship_event.update!(feedback: feedback)
        feedback
      else
        Rails.logger.error "Failed to generate ship feedback for ship_event #{@ship_event.id}: Empty response"
        nil
      end
    rescue => e
      Rails.logger.error "Failed to generate ship feedback for ship_event #{@ship_event.id}: #{e.message}"
      nil
    end
  end

  private

  def collect_payout_votes
    project = @ship_event.project
    
    Vote.joins(:vote_changes)
        .where(vote_changes: { project: project })
        .where("votes.created_at > ?", @ship_event.created_at)
        .where(status: 'active')
        .includes(:user)
        .limit(18) 
  end

  def build_feedback_prompt(explanations)
    project_name = @ship_event.project.title
    
    <<~PROMPT
      You are an expert project reviewer providing constructive feedback for a shipped project called "#{project_name}".

      Based on the voter feedback provided, write a concise summary paragraph that addresses:

      1. Overall community reception and sentiment
      2. Top 2-3 strengths consistently mentioned by voters
      3. Most actionable improvement suggestions or recurring themes

      REQUIREMENTS:
      Write in plain text only (no markdown, headers, or bullet points)
      Keep to exactly 4-5 sentences in a single paragraph
      Maintain an encouraging and constructive tone
      Prioritize the most significant and recurring feedback points
      Use specific language rather than generic praise
      If feedback is mixed, acknowledge both positives and areas for growth

      Voter Feedback Data:
      #{explanations}
    PROMPT
  end
end