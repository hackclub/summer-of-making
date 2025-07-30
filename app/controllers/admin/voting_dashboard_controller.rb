module Admin
  class VotingDashboardController < ApplicationController
    def index
      @total = Vote.count
      @pool = Project.count

      counts = Vote.group(:project_1_id).count.merge(Vote.group(:project_2_id).count) { |_, a, b| a + b }
      vote_counts = counts.values

      @v1 = vote_counts.count { |c| c >= 1 }
      @v5 = vote_counts.count { |c| c >= 5 }
      @v10 = vote_counts.count { |c| c >= 10 }
      @v18 = vote_counts.count { |c| c >= 18 }
      @v24 = vote_counts.count { |c| c >= 24 }
      @v30 = vote_counts.count { |c| c >= 30 }
      @v50 = vote_counts.count { |c| c >= 50 }

      @top10 = Project.order(rating: :desc).limit(10)
      @bottom10 = Project.order(rating: :asc).limit(10)

      votes = Vote.order(created_at: :desc).limit(10).includes(:user, :project_1, :project_2)
      @flagged_votes = []
      votes.each do |vote|
        ai_feedback = analyze_vote_with_ai(vote)
        if ai_feedback[:flagged]
          @flagged_votes << [ vote, ai_feedback[:reason] ]
        end
      end

      if params[:show_last_15]
        @last_15_votes = Vote.order(created_at: :desc).limit(15).includes(:user, :project_1, :project_2)
      end
    end

    private

    def analyze_vote_with_ai(vote)
      prompt = <<~PROMPT
        Analyze the following vote for quality. Is it likely written by AI (look for em dashes or generic language)? Does it relate to the two projects below? Reply with a short reason if flagged, or 'OK' if not.

        Vote: #{vote.text}
        Project 1: #{vote.project_1&.name}
        Project 2: #{vote.project_2&.name}
      PROMPT

      response = Faraday.post("https://ai.hackclub.com/chat/completions/no_think", { prompt: prompt }.to_json, "Content-Type" => "application/json")
      body = JSON.parse(response.body)
      feedback = body["choices"]&.first&.dig("message", "content") || "No response"
      flagged = feedback != "OK"
      { flagged: flagged, reason: feedback }
    rescue => e
      { flagged: false, reason: "AI error: #{e.message}" }
    end
  end
end
