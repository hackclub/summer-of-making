class OneTime::FixGithubRepoApiLinksJob < ApplicationJob
  queue_as :default

  def perform(dry_run: false, limit: nil)
    mode = dry_run ? "DRY RUN" : "LIVE"
    Rails.logger.info "Starting to fix GitHub repo URLs using API (#{mode})..."

    updated_count = 0
    skipped_count = 0
    failed_count = 0

    # Find projects with GitHub URLs that aren't already raw
    projects = Project.where(
      "readme_link LIKE '%github.com%' AND readme_link NOT LIKE '%raw.githubusercontent.com%' AND readme_link IS NOT NULL"
    )
    projects = projects.limit(limit) if limit

    projects.find_each do |project|
      original_link = project.readme_link

      # Try to convert using GitHub API
      converted_link = convert_github_repo_to_raw(original_link)

      if converted_link && converted_link != original_link
        if dry_run
          updated_count += 1
          Rails.logger.info "[DRY RUN] Would update project #{project.id}: #{original_link} -> #{converted_link}"
        else
          begin
            project.update!(readme_link: converted_link)
            updated_count += 1
            Rails.logger.info "Updated project #{project.id}: #{original_link} -> #{converted_link}"
          rescue => e
            failed_count += 1
            Rails.logger.error "Failed to update project #{project.id}: #{e.message}"
          end
        end
      else
        skipped_count += 1
        Rails.logger.debug "Skipped project #{project.id}: #{original_link} (no API conversion available)"
      end
    end

    Rails.logger.info "Completed GitHub API link fixing (#{mode}): #{updated_count} updated, #{skipped_count} skipped, #{failed_count} failed"
  end

  private

  def convert_github_repo_to_raw(url)
    return nil unless url&.include?("github.com")

    # Extract user and repo from any GitHub URL pattern
    # Handles typos, invalid paths, #readme, etc.
    repo_match = url.match(%r{https://github\.com/([^/]+)/([^/#?]+)})
    return nil unless repo_match

    user = repo_match[1]
    repo = repo_match[2]

    # Use GitHub API to get README info
    api_url = "https://api.github.com/repos/#{user}/#{repo}/readme"
    response = Faraday.get(api_url)

    if response.success?
      readme_data = JSON.parse(response.body)
      readme_data["download_url"]
    elsif response.status == 403
      raise "GitHub API rate limit exceeded. Try running from a different IP or wait an hour."
    else
      Rails.logger.debug "GitHub API returned #{response.status} for #{user}/#{repo}: #{response.body[0..200]}"
      nil
    end
  rescue JSON::ParserError => e
    Rails.logger.debug "Failed to parse GitHub API response for #{user}/#{repo}: #{e.message}"
    nil
  end
end
