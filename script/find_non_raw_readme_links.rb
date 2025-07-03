#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to find all projects with non-raw GitHub README links
# and demonstrate conversion to raw format

# Load Rails environment
require_relative '../config/environment'

def convert_github_blob_to_raw(url)
  return url unless url&.include?('github.com')

  # Pattern: https://github.com/user/repo/blob/branch/path/to/file
  # Convert to: https://raw.githubusercontent.com/user/repo/branch/path/to/file
  url.gsub(%r{https://github\.com/([^/]+)/([^/]+)/blob/(.+)}, 'https://raw.githubusercontent.com/\1/\2/\3')
end

puts "Finding projects with non-raw GitHub README links..."
puts "=" * 60

# Find all projects with GitHub blob links (not raw links)
non_raw_projects = Project.where(
  "readme_link LIKE '%github.com%' AND readme_link NOT LIKE '%raw.githubusercontent.com%' AND readme_link IS NOT NULL"
)

puts "Found #{non_raw_projects.count} projects with non-raw GitHub README links:"
puts ""

if non_raw_projects.any?
  non_raw_projects.each do |project|
    puts "Project ID: #{project.id}"
    puts "Title: #{project.title}"
    puts "Current README link: #{project.readme_link}"

    # Convert the link to raw format
    converted_link = convert_github_blob_to_raw(project.readme_link)
    puts "Converted link: #{converted_link}"
    puts "Would update: #{project.readme_link != converted_link}"
    puts "-" * 40
  end

else
  puts "No non-raw GitHub README links found!"
  puts ""
  puts "Sample conversion examples:"
  test_links = [
    "https://github.com/user/repo/blob/main/README.md",
    "https://github.com/user/repo/blob/master/README.md",
    "https://github.com/user/repo/blob/develop/docs/README.md"
  ]

  test_links.each do |link|
    puts "#{link} -> #{convert_github_blob_to_raw(link)}"
  end
end
