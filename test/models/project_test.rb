# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                     :bigint           not null, primary key
#  category               :string
#  certification_type     :integer
#  demo_link              :string
#  description            :text
#  devlogs_count          :integer          default(0), not null
#  followers_count        :integer          default(0), not null
#  hackatime_project_keys :string           default([]), is an Array
#  is_deleted             :boolean          default(FALSE)
#  is_shipped             :boolean          default(FALSE)
#  is_sinkening_ship      :boolean          default(FALSE)
#  magicked_at            :datetime
#  rating                 :integer
#  readme_link            :string
#  repo_link              :string
#  ship_events_count      :integer          default(0), not null
#  title                  :string
#  used_ai                :boolean
#  views_count            :integer          default(0), not null
#  x                      :float
#  y                      :float
#  ysws_submission        :boolean          default(FALSE), not null
#  ysws_type              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_projects_on_followers_count         (followers_count)
#  index_projects_on_is_shipped              (is_shipped)
#  index_projects_on_rating                  (rating)
#  index_projects_on_ship_events_count       (ship_events_count)
#  index_projects_on_user_id                 (user_id)
#  index_projects_on_user_id_and_is_deleted  (user_id,is_deleted)
#  index_projects_on_views_count             (views_count)
#  index_projects_on_x_and_y                 (x,y)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @user = users(:tom)
    @project = Project.new(
      title: "Test Project",
      description: "A test project",
      user: @user
    )
  end

  test "should be valid with valid attributes" do
    assert @project.valid?
  end

  test "should accept valid HTTP URLs for demo_link" do
    @project.demo_link = "http://example.com"
    assert @project.valid?
  end

  test "should accept valid HTTPS URLs for demo_link" do
    @project.demo_link = "https://example.com"
    assert @project.valid?
  end

  test "should reject javascript URLs for demo_link" do
    @project.demo_link = "javascript:alert('xss')"
    assert_not @project.valid?
    assert_includes @project.errors[:demo_link], "must be a valid HTTP or HTTPS URL"
  end

  test "should reject data URLs for demo_link" do
    @project.demo_link = "data:text/html,<script>alert('xss')</script>"
    assert_not @project.valid?
    assert_includes @project.errors[:demo_link], "must be a valid HTTP or HTTPS URL"
  end

  test "should reject file URLs for demo_link" do
    @project.demo_link = "file:///etc/passwd"
    assert_not @project.valid?
    assert_includes @project.errors[:demo_link], "must be a valid HTTP or HTTPS URL"
  end

  test "should reject ftp URLs for demo_link" do
    @project.demo_link = "ftp://example.com/file.txt"
    assert_not @project.valid?
    assert_includes @project.errors[:demo_link], "must be a valid HTTP or HTTPS URL"
  end

  test "should accept valid HTTP URLs for repo_link" do
    @project.repo_link = "http://github.com/user/repo"
    assert @project.valid?
  end

  test "should reject javascript URLs for repo_link" do
    @project.repo_link = "javascript:alert('xss')"
    assert_not @project.valid?
    assert_includes @project.errors[:repo_link], "must be a valid HTTP or HTTPS URL"
  end

  test "should accept valid HTTP URLs for readme_link" do
    @project.readme_link = "http://github.com/user/repo/readme.md"
    assert @project.valid?
  end

  test "should reject javascript URLs for readme_link" do
    @project.readme_link = "javascript:alert('xss')"
    assert_not @project.valid?
    assert_includes @project.errors[:readme_link], "must be a valid HTTP or HTTPS URL"
  end
end
