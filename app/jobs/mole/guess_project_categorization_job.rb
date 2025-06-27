class Mole::GuessProjectCategorizationJob < ApplicationJob
  queue_as :literally_whenever

  def perform(project_id)
    project = Project.find(project_id)

    # Skip if already categorized
    return if project.certification_type.present? && project.category.present?

    # Get project URLs
    urls = [
      project.demo_link,
      project.repo_link,
      project.readme_link
    ].reject { |c| c.empty? }.compact.uniq

    Rails.logger.info "Project #{project_id} URLs: #{urls.join(', ')}"

    # Skip if no URLs to analyze
    return if urls.empty?

    # Classification prompt
    task_prompt = build_classification_prompt

    # Call mole browser service
    response = call_mole_service(task_prompt, urls)

    if response[:success] && response[:result]
      update_project_classification(project, response[:result])

      # Log the GIF URL if available
      if response[:gif_url].present?
        Rails.logger.info "Project #{project_id} classification GIF: #{response[:gif_url]}"
      end
    else
      Rails.logger.error "Failed to classify project #{project_id}: #{response[:error]}"
    end
  end

  private

  def build_classification_prompt
    cert_types = Project.certification_types.keys

    <<~PROMPT
      You are helping a hackathon project reviewer for an adventure-themed hackathon. You are a mascot mole, the thing that digs in the dirt and can't see well.

      Analyze this project to classify how it can be tested on the provided URLs (README, demo/play link, and repository).

      Visit these links and determine a classification: #{cert_types.join(', ')}
      If you are already sure, you don't need to visit every link. For example, if a release includes an APK file, you can skip the demo/play link.
      If you are low confidence, or the main categories don't seem to fit, return "cert_other".
      Projects that can't be used as an app (ie. a research paper isn't runable, ipynotebook etc.) should be "cert_other".
      Projects that use a video as their demo link should be classified as video.

      Base your decision on:
      - Code in the repository (languages, frameworks, dependencies)
      - Demo/play functionality if available
      - README description and documentation
      - Project structure and build files

      Your decision is based on how to test the app- for example, a pygame app without an executable would be a command_line app. A pygame with an executable would be a desktop_app.

      Return your classification in this EXACT format:
      CERT_TYPE|CONFIDENCE|REASONING

      Where:
      - CERT_TYPE is one of: #{cert_types.join(', ')}
      - CONFIDENCE is a number between 0 and 1 (e.g., 0.95)
      - REASONING is a brief explanation of why you chose this classification. 1 sentence tops. No yapping.

      Examples:
      web_app|0.85|Uses React framework with API calls and deployment to Vercel
      static_site|0.9|This is a github.io link, so it's hosted on github pages

      Return ONLY this pipe-separated format. No other text.
    PROMPT
  end

  def call_mole_service(task_prompt, urls)
    uri = URI("http://host.docker.internal:5001/run")
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 300  # 5 minutes
    http.open_timeout = 30   # 30 seconds to establish connection

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      task: task_prompt,
      urls: urls,
      provider: "anthropic",
      model: "claude-3-7-sonnet-20250219",
      api_key: ENV["ANTHROPIC_API_KEY"]
    }.to_json

    response = http.request(request)

    # Debug logging
    Rails.logger.info "Mole service response status: #{response.code}"
    Rails.logger.info "Mole service response body: #{response.body.inspect}"

    # Check if response is successful
    unless response.is_a?(Net::HTTPSuccess)
      return { success: false, error: "HTTP #{response.code}: #{response.body}" }
    end

    # Check if response body is empty
    if response.body.nil? || response.body.strip.empty?
      return { success: false, error: "Empty response from mole service" }
    end

    # Parse the response as pipe-separated format instead of JSON
    response_data = JSON.parse(response.body).with_indifferent_access
    response_data
  rescue JSON::ParserError => e
    Rails.logger.error "JSON parse error: #{e.message}, body: #{response&.body.inspect}"
    { success: false, error: "Invalid JSON response: #{e.message}" }
  rescue => e
    Rails.logger.error "Mole service error: #{e.message}"
    { success: false, error: e.message }
  end

  def update_project_classification(project, result)
    # Parse pipe-separated result: CERT_TYPE|CONFIDENCE|REASONING
    if result.is_a?(String)
      parts = result.strip.split("|", 3)
      if parts.length >= 3
        cert_type = parts[0].strip
        confidence = parts[1].strip.to_f
        reasoning = parts[2].strip

        Rails.logger.info "Parsed classification: #{cert_type} (confidence: #{confidence}) - #{reasoning}"

        # Update project with classification
        project.update!(
          certification_type: cert_type
        )

        Rails.logger.info "Updated project #{project.id} classification: #{cert_type}"
      else
        Rails.logger.error "Invalid pipe-separated format: #{result}"
      end
    else
      Rails.logger.error "Expected string result, got #{result.class}: #{result}"
    end
  rescue => e
    Rails.logger.error "Failed to update project #{project.id} classification: #{e.message}"
  end
end
