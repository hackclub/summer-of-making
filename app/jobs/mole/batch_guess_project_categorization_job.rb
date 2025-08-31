class Mole::BatchGuessProjectCategorizationJob < ApplicationJob
  queue_as :literally_whenever

  BATCH_SIZE = 2

  def perform(project_ids = nil, recurring = false)
    @project_ids = project_ids || get_default_project_ids
    Rails.logger.info "Starting batch categorization for #{@project_ids.length} projects"

    mole_service = MoleBrowserService.new(timeout: 600) # 10 minutes timeout for batch

    # Prepare tasks for batch processing
    tasks = prepare_tasks(@project_ids)
    return if tasks.empty?

    # Submit all jobs to mole service
    job_submissions = mole_service.submit_batch_jobs(tasks)

    # Poll all jobs until completion
    mole_service.poll_batch_jobs(job_submissions) do |submission, job_data, status|
      handle_job_result(submission, job_data, status)
    end

    Rails.logger.info "Completed batch categorization for #{@project_ids.length} projects"

    if recurring && @project_ids.length == BATCH_SIZE
      perform(nil, true)
    end
  end

  private

  def get_default_project_ids
    # Find projects with ship events, prioritizing nil cert_type then "other"
    # Only include projects with at least one URL available
    Project.joins(:ship_events)
           .where(certification_type: [ nil, :cert_other ])
           .where.not(demo_link: "")
           .where.not(repo_link: "")
           .where.not(readme_link: "")
           .order("certification_type NULLS FIRST")
           .limit(BATCH_SIZE)
           .pluck(:id)
  end

  def prepare_tasks(project_ids)
    tasks = []

    project_ids.each do |project_id|
      project = Project.find(project_id)

      # Skip if already categorized
      if project.certification_type.present? && !project.cert_other? && project.category.present?
        Rails.logger.info "Skipping project #{project_id} - already categorized"
        next
      end

      # Get project URLs
      urls = [
        project.demo_link,
        project.repo_link,
        project.readme_link
      ].reject { |c| c.empty? }.compact.uniq

      # Skip if no URLs to analyze
      if urls.empty?
        Rails.logger.info "Skipping project #{project_id} - no URLs available"
        next
      end

      tasks << {
        name: "project_#{project_id}",
        project_id: project_id,
        project: project,
        prompt: build_classification_prompt,
        urls: urls
      }
    end

    tasks
  end

  def handle_job_result(submission, job_data, status)
    case status
    when :completed
      result = job_data["result"]
      if result && result["success"]
        update_project_classification(submission[:project], result["result"])

        if result["gif_url"].present?
          Rails.logger.info "Project #{submission[:project_id]} classification GIF: #{result['gif_url']}"
        end

        Rails.logger.info "Successfully categorized project #{submission[:project_id]}"
      else
        Rails.logger.error "Failed to categorize project #{submission[:project_id]}: #{result&.dig('error') || 'No result'}"
      end
    when :failed
      error = job_data&.dig("error") || "Unknown error"
      Rails.logger.error "Failed to categorize project #{submission[:project_id]}: #{error}"
    when :timeout
      Rails.logger.error "Job for project #{submission[:project_id]} timed out"
    end
  end

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

      If it helps, you can visualize the filetree using https://githubtree.mgks.dev/ (for example, https://githubtree.mgks.dev/repo/hackclub/site/main/)

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
      cert_other|0.1|This is a repo of only markdown files so it's not clear how to test this

      Return ONLY this pipe-separated format. No other text.
    PROMPT
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
