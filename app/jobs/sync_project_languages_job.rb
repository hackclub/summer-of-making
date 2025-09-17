class SyncProjectLanguagesJob < ApplicationJob
  queue_as :literally_whenever

  def perform
    Rails.logger.info "Starting ProjectLanguages sync job"

    # Find projects that need language syncing using the scope
    projects_to_sync = Project.needs_language_sync.limit(25).to_a

    Rails.logger.info "Found #{projects_to_sync.count} projects to sync"

    return if projects_to_sync.empty?

    # Process all projects in parallel
    sync_results = process_projects_in_parallel(projects_to_sync)

    # Perform batch upsert
    batch_upsert_project_languages(sync_results)

    Rails.logger.info "Completed ProjectLanguages sync job"
  end

  private

  def process_projects_in_parallel(projects)
    Rails.logger.info "Starting #{projects.count} threads for parallel processing"

    threads = projects.map do |project|
      Thread.new do
        sync_project_languages(project)
      rescue StandardError => e
        Rails.logger.error "Thread failed for project #{project.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        nil
      end
    end

    Rails.logger.info "All threads created, waiting for completion..."
    threads.map(&:value).compact
  end

  def sync_project_languages(project)
    unless project.repo_link.present?
      Rails.logger.warn "Project #{project.id} has no repo_link, skipping"
      return {
        project_id: project.id,
        status: :failed,
        language_stats: {},
        error_message: "No repository link provided",
        last_synced_at: Time.current
      }
    end

    owner, repo = extract_github_info(project.repo_link)
    unless owner && repo
      Rails.logger.warn "Project #{project.id} has invalid repo format: #{project.repo_link}"
      return {
        project_id: project.id,
        status: :failed,
        language_stats: {},
        error_message: "Invalid GitHub repository URL format: #{project.repo_link}",
        last_synced_at: Time.current
      }
    end

    Rails.logger.info "Making request for project #{project.id}: #{owner}/#{repo}"

    begin
      github_service = GithubProxyService.new
      language_stats = github_service.get_repository_languages(owner, repo)

      Rails.logger.info "Successfully synced languages for project #{project.id}: #{language_stats.keys.join(', ')}"

      {
        project_id: project.id,
        status: :synced,
        language_stats: language_stats,
        error_message: nil,
        last_synced_at: Time.current
      }
    rescue GithubProxyService::GithubProxyError => e
      Rails.logger.warn "GitHub API error for project #{project.id}: #{e.message}"

      {
        project_id: project.id,
        status: :failed,
        language_stats: {},
        error_message: e.message,
        last_synced_at: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "Unexpected error syncing project #{project.id}: #{e.message}"

      {
        project_id: project.id,
        status: :failed,
        language_stats: {},
        error_message: e.message,
        last_synced_at: Time.current
      }
    end
  end

  def batch_upsert_project_languages(sync_results)
    return if sync_results.empty?

    upsert_data = sync_results.map do |result|
      {
        project_id: result[:project_id],
        status: result[:status],
        language_stats: result[:language_stats],
        error_message: result[:error_message],
        last_synced_at: result[:last_synced_at],
        created_at: Time.current
      }
    end

    ProjectLanguage.upsert_all(
      upsert_data,
      unique_by: :project_id,
      update_only: [ :status, :error_message, :last_synced_at ]
    )

    Rails.logger.info "Batch upserted #{upsert_data.count} project language records"
  end

  def extract_github_info(repo_link)
    return nil unless repo_link.present?

    # Handle various GitHub URL formats
    uri = URI.parse(repo_link.strip)
    path = uri.path.sub(/^\//, "").sub(/\.git$/, "").split("/")

    return nil unless path.length >= 2

    owner = path[0]
    repo = path[1]

    return nil if owner.blank? || repo.blank?

    [ owner, repo ]
  rescue URI::InvalidURIError
    Rails.logger.warn "Invalid repo URL format: #{repo_link}"
    nil
  end
end
