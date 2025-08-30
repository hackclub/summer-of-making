# == Schema Information
#
# Table name: fraud_reports
#
#  id             :bigint           not null, primary key
#  category       :string
#  reason         :string
#  resolved       :boolean          default(FALSE), not null
#  resolved_at    :datetime
#  suspect_type   :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resolved_by_id :bigint
#  suspect_id     :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_fraud_reports_on_category          (category)
#  index_fraud_reports_on_resolved_by_id    (resolved_by_id)
#  index_fraud_reports_on_user_and_suspect  (user_id,suspect_type,suspect_id) UNIQUE
#  index_fraud_reports_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (resolved_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class FraudReportTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @project = projects(:one)
  end

  test "should be valid with valid attributes" do
    fraud_report = FraudReport.new(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )
    assert fraud_report.valid?
  end

  test "should not allow duplicate reports from same user for same project" do
    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    duplicate_report = FraudReport.new(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "fake_project"
    )

    assert_not duplicate_report.valid?
    assert_includes duplicate_report.errors[:user_id], "You have already reported this project"
  end

  test "should allow different users to report the same project" do
    other_user = users(:two)

    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    second_report = FraudReport.new(
      reporter: other_user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "fake_project"
    )

    assert second_report.valid?
  end

  test "should allow same user to report different projects" do
    other_project = projects(:two)

    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    second_report = FraudReport.new(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: other_project.id,
      reason: "fake_project"
    )

    assert second_report.valid?
  end

  test "already_reported_by? should return true for reported projects" do
    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    assert FraudReport.already_reported_by?(@user, @project)
  end

  test "already_reported_by? should return false for non-reported projects" do
    assert_not FraudReport.already_reported_by?(@user, @project)
  end

  test "already_reported_by? should return false for different users" do
    other_user = users(:two)

    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    assert_not FraudReport.already_reported_by?(other_user, @project)
  end
end
