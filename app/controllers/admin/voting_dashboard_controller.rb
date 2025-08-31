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

      # we only want to get projects that are matured in some sense otherwise SD will be super low (well, not really because for some stupid reason two projects on either end are kinda outlier? i would ignore those... but chris...) if we have no min_votes because default is like... 1100? almost the entire dataset will be centered around the mean
      scope = Project.joins(:vote_changes)
                     .group("projects.id")
                     .having("COUNT(vote_changes.id) >= ?", 18)

      ratings = scope.where.not(rating: nil).pluck("projects.rating")
      if ratings.any?
        @ratings_count = ratings.size
        @rating_min = ratings.min
        @rating_max = ratings.max

        mean = ratings.sum.to_f / @ratings_count
        variance = ratings.sum { |r| (r - mean) ** 2 } / [ @ratings_count, 1 ].max.to_f
        stddev = Math.sqrt(variance)
        stddev = 1.0 if stddev.zero?
        @rating_mean = mean
        @rating_stddev = stddev

        sturges_bins = (Math.log2(@ratings_count).ceil + 1).clamp(5, 60)
        @rating_bins = (params[:bins] || sturges_bins).to_i.clamp(5, 100)
        span = (@rating_max - @rating_min).to_f
        bin_width = [ span / @rating_bins, 1.0 ].max
        @rating_bin_width = bin_width
        @rating_bin_edges = Array.new(@rating_bins + 1) { |i| (@rating_min + i * bin_width).round }

        # code beyond this is AI generated and i'll have to review this later... gonna merge it now tho
        counts = Array.new(@rating_bins, 0)
        ratings.each do |r|
          idx = ((r - @rating_min) / bin_width).floor
          idx = @rating_bins - 1 if idx >= @rating_bins
          idx = 0 if idx < 0
          counts[idx] += 1
        end
        @rating_hist_counts = counts
        max_count = counts.max
        @rating_hist_max_count = max_count
        # Normalized for easier rendering in view
        @rating_hist_norm = max_count.to_i.zero? ? counts.map { 0.0 } : counts.map { |c| c.to_f / max_count }

        # Normal curve at bin centers, normalized to [0,1]
        two_pi = Math::PI * 2.0
        densities = []
        @rating_bins.times do |i|
          center = @rating_min + (i + 0.5) * bin_width
          z = (center - mean) / stddev
          density = Math.exp(-0.5 * z * z) / (stddev * Math.sqrt(two_pi))
          densities << density
        end
        max_density = densities.max || 1.0
        max_density = 1.0 if max_density.zero?
        @rating_curve_norm = densities.map { |d| d / max_density }
      else
        @ratings_count = 0
        @rating_min = 0
        @rating_max = 0
        @rating_bins = 0
        @rating_bin_width = 0
        @rating_hist_counts = []
        @rating_hist_max_count = 0
        @rating_hist_norm = []
        @rating_mean = 0
        @rating_stddev = 1
        @rating_curve_norm = []
        @rating_bin_edges = []
      end

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
