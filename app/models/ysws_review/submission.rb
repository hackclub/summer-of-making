# == Schema Information
#
# Table name: ysws_review_submissions
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#  reviewer_id :bigint           not null
#
# Indexes
#
#  index_ysws_review_submissions_on_project_id   (project_id) UNIQUE
#  index_ysws_review_submissions_on_reviewer_id  (reviewer_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (reviewer_id => users.id)
#
class YswsReview::Submission < ApplicationRecord
  include AirtableSyncable
  include ActionView::Helpers::TextHelper  # For pluralize method

  belongs_to :project
  belongs_to :reviewer, class_name: "User", optional: true
  validates :project, uniqueness: true

  airtable_table_name "ysws_submission"

  # Set the class method to return current mappings dynamically
  def self.airtable_field_mappings
    # This is a bit of a hack, but we need dynamic mappings per instance
    # The AirtableSyncJob will override this with airtable_mapped_data anyway
    {}
  end

  # Override the AirtableSyncable method to use dynamic field mappings
  def airtable_field_mappings
    current_field_mappings
  end

  # Different field mappings for initial sync vs updates
  def initial_sync_field_mappings
    {
      "Code URL" => "project.repo_link",
      "Playable URL" => "project.demo_link",
      "Email" => "project.user.email",
      "First Name" => "user_first_name",
      "Last Name" => "user_last_name",
      "GitHub Username" => "github_username",
      "Screenshot" => "banner_attachment_for_airtable",
      "Description" => "project.description",
      "Address (Line 1)" => "user_address_line_1",
      "Address (Line 2)" => "user_address_line_2",
      "City" => "user_city",
      "State / Province" => "user_state",
      "ZIP / Postal Code" => "user_postal_code",
      "Country" => "user_country",
      "Birthday" => "user_birthday",
      "Optional - Override Hours Spent" => "total_approved_hours",
      "Optional - Override Hours Spent Justification" => "hours_justification",
      "Reviewer" => "reviewer_display_name",
      "project" => "project_airtable_record_id"
    }
  end

  def update_sync_field_mappings
    {
      "Code URL" => "project.repo_link",
      "Playable URL" => "project.demo_link",
      "Screenshot" => "banner_attachment_for_airtable",
      "Description" => "project.description",
      "Optional - Override Hours Spent" => "total_approved_hours",
      "Optional - Override Hours Spent Justification" => "hours_justification",
      "First Name" => "user_first_name",
      "Last Name" => "user_last_name",
      "Email" => "project.user.email",
      "Address (Line 1)" => "user_address_line_1",
      "Address (Line 2)" => "user_address_line_2",
      "City" => "user_city",
      "State / Province" => "user_state",
      "ZIP / Postal Code" => "user_postal_code",
      "Country" => "user_country",
      "Birthday" => "user_birthday",
      "Reviewer" => "reviewer_display_name",
      "project" => "project_airtable_record_id"
    }
  end

  def is_initial_sync?
    airtable_record_id.blank?
  end

  def current_field_mappings
    is_initial_sync? ? initial_sync_field_mappings : update_sync_field_mappings
  end

  def banner_attachment_for_airtable
    return nil unless project.banner.attached?

    url = project.banner.blob.url
    filename = project.banner.filename.to_s

    # This is the format airtable expects for attachment fields
    [ {
      "url" => url,
      "filename" => filename
    } ]
  end

  # Helper methods for computed fields used in airtable_field_mappings
  def user_first_name
    user_identity[:first_name]
  end

  def user_last_name
    user_identity[:last_name]
  end

  def reviewer_display_name
    reviewer&.display_name
  end

  def github_username
    # Only extract GitHub username if we're confident it's correct
    # Validate by checking consistency across user's other projects
    return nil unless project.repo_link.present?

    # Only handle GitHub URLs
    return nil unless project.repo_link.match?(/^https:\/\/github\.com\//)

    # Extract username from current project's URL
    match = project.repo_link.match(/^https:\/\/github\.com\/([^\/]+)\/([^\/]+)/)
    return nil unless match

    current_username = match[1]

    # Check user's other projects to validate this username
    user_github_usernames = project.user.projects
      .where.not(id: project.id)  # Exclude current project
      .where.not(repo_link: [ nil, "" ])  # Only projects with repo links
      .filter_map do |other_project|
        next unless other_project.repo_link.match?(/^https:\/\/github\.com\//)

        other_match = other_project.repo_link.match(/^https:\/\/github\.com\/([^\/]+)\/([^\/]+)/)
        other_match ? other_match[1] : nil
      end

    # Only return username if we've seen it in other projects (confidence check)
    # If user has no other GitHub projects, we'll be less confident and return nil
    return nil unless user_github_usernames.include?(current_username)

    current_username
  end

  def user_address_line_1
    user_identity[:addresses]&.first&.dig(:line_1)
  end

  def user_address_line_2
    user_identity[:addresses]&.first&.dig(:line_2)
  end

  def user_city
    user_identity[:addresses]&.first&.dig(:city)
  end

  def user_state
    user_identity[:addresses]&.first&.dig(:state)
  end

  def user_postal_code
    user_identity[:addresses]&.first&.dig(:postal_code)
  end

  def user_country
    user_identity[:addresses]&.first&.dig(:country)
  end

  def user_birthday
    user_identity[:birthday]
  end

  def project_airtable_record_id
    return [] unless project.airtable_synced?
    [ project.airtable_record_id ]
  end

  def total_approved_seconds
    project.devlogs.joins(:ysws_review_approval)
           .where(ysws_review_devlog_approvals: { approved: true })
           .sum("ysws_review_devlog_approvals.approved_seconds")
  end

  def total_approved_hours
    total_approved_seconds / 3600.0
  end

  def hours_justification
    # return nil unless fully_reviewed?

    approved_devlogs = project.devlogs.joins(:ysws_review_approval)
                              .where(ysws_review_devlog_approvals: { approved: true })
                              .includes(:ysws_review_approval)

    return nil if approved_devlogs.empty?

    total_hours = total_approved_hours

    justification = []

    justification << "This user logged #{pluralize(pretty_round(total_hours), 'hour')} in hackatime. "

    if approved_devlogs.size > 1
      justification << "They have #{pluralize(approved_devlogs.size, 'devlog')} to show their work:\n\n"

      # prevent wasting a line on "... and 1 more 1 devlog at LINK"

      list_size = approved_devlogs.size > 4 ? 3 : approved_devlogs.size

      approved_devlogs.limit(list_size).each do |devlog|
        approved_hours = devlog.ysws_review_approval.approved_seconds / 3600.0
        devlog_url = "https://summer.hackclub.com/projects/#{project.id}#devlog_#{devlog.id}"
        devlog_desc = devlog.text
                            .gsub(/[\n\r]/, " ")
                            .truncate(50, separator: " ")
        justification << "- [#{devlog_desc.strip}](#{devlog_url}) (#{approved_hours.round(1)} hrs)\n"
      end

      if approved_devlogs.size > list_size
        leftover = approved_devlogs.size - list_size
        justification << "... and #{leftover} more #{pluralize(leftover, 'devlog')} at https://summer.hackclub.com/projects/#{project.id}."
      end
    else
      justification << "They have this devlog which shows their work: https://summer.hackclub.com/projects/#{project.id}#devlog_#{approved_devlogs.first&.id}."
    end

    if project.ship_certifications.approved.exists?
      justification << "\nAlso, #{project.ship_certifications.approved.first&.reviewer&.display_name} tested their project out"
      justification << " and recorded themselves using it (click 'ship certified' to see the video)" if project.ship_certifications.approved.first&.proof_video&.attached?
      justification << "."
    end

    justification << "\n\nThese hours were reviewed by #{reviewer.display_name}."

    justification.join
  end

  def fully_reviewed?
    project.devlogs.where.missing(:ysws_review_approval).empty? &&
    project.devlogs.joins(:ysws_review_approval).any?
  end

  private

  def pretty_round(number, precision: 1)
    NumberFormatting.pretty_round(number, precision: precision)
  end

  def user_identity
    @user_identity ||= project.user.fetch_idv[:identity] || {}
  end
end
