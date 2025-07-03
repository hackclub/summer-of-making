class OneTime::FixNonRawGithubReadmeLinksJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting to fix non-raw GitHub README links..."

    updated_count = 0
    skipped_count = 0

    # Find projects with GitHub blob README links that can be automatically converted
    Project.where(
      "readme_link LIKE '%github.com%' AND readme_link NOT LIKE '%raw.githubusercontent.com%' AND readme_link IS NOT NULL"
    ).find_each do |project|
      original_link = project.readme_link
      converted_link = convert_github_blob_to_raw(original_link)

      if should_update_link?(original_link, converted_link)
        begin
          project.update!(readme_link: converted_link)
          updated_count += 1
          Rails.logger.info "Updated project #{project.id}: #{original_link} -> #{converted_link}"
        rescue => e
          Rails.logger.error "Failed to update project #{project.id}: #{e.message}"
        end
      else
        skipped_count += 1
        Rails.logger.debug "Skipped project #{project.id}: #{original_link} (not a simple blob URL)"
      end
    end

    Rails.logger.info "Completed README link fixing: #{updated_count} updated, #{skipped_count} skipped"
  end

  private

  def convert_github_blob_to_raw(url)
    return url unless url&.include?("github.com")

    # Only convert github.com/user/repo/blob/ URLs to raw format
    # Pattern: https://github.com/user/repo/blob/branch/path/to/file
    # Convert to: https://raw.githubusercontent.com/user/repo/branch/path/to/file
    if url.match?(%r{https://github\.com/[^/]+/[^/]+/blob/})
      url.gsub(%r{https://github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'https://raw.githubusercontent.com/\1/\2/\3')
    else
      url # Return unchanged if not a blob URL
    end
  end

  def should_update_link?(original, converted)
    # Only update if:
    # 1. The conversion actually changed something
    # 2. It's not already a raw link
    # 3. It's a simple blob URL (not special GitHub URLs like #readme, /edit/, etc.)
    original != converted &&
    !original.include?("raw.githubusercontent.com") &&
    !original.include?("#") &&
    !original.include?("/edit/") &&
    !original.include?("/tree/") &&
    !original.include?("/commit/") &&
    !original.include?("/commits") &&
    !original.include?("/docs/") &&
    original.include?("/blob/")
  end
end
