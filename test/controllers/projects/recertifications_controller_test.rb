require "test_helper"

class Projects::RecertificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    @project.update!(user: @user)
    sign_in @user

    # Create a ship certification and mark it as rejected
    @certification = ShipCertification.create!(
      project: @project,
      reviewer: users(:admin),
      judgement: :rejected,
      rejection_reason: "Needs improvement"
    )
  end

  test "should request recertification before deadline" do
    # Freeze time before deadline
    travel_to Time.zone.local(2025, 10, 1, 12, 0, 0) do
      assert_difference("ShipCertification.count") do
        post project_recertifications_path(@project), params: {
          recertification_instructions: "I fixed the issues"
        }
      end

      assert_redirected_to project_path(@project)
      assert_equal "Re-certification requested! Your project will be reviewed again.", flash[:notice]

      # Verify user doesn't have post-deadline permission
      refute @user.reload.has_permission?("post_deadline_recert_used")
      refute @user.has_permission?("no_recert")
    end
  end

  test "should allow one post-deadline recertification" do
    # Freeze time after deadline
    travel_to Time.zone.local(2025, 10, 3, 12, 0, 0) do
      assert_difference("ShipCertification.count") do
        post project_recertifications_path(@project), params: {
          recertification_instructions: "Please review again"
        }
      end

      assert_redirected_to project_path(@project)
      assert_equal "Last Re-certification requested! Your project will be reviewed again.", flash[:notice]

      # Verify user has used their post-deadline chance
      assert @user.reload.has_permission?("post_deadline_recert_used")
      refute @user.has_permission?("no_recert")
    end
  end

  test "should block user after using post-deadline recertification" do
    # Mark user as having used post-deadline recert
    @user.add_permission("post_deadline_recert_used")

    # Freeze time after deadline
    travel_to Time.zone.local(2025, 10, 3, 12, 0, 0) do
      assert_no_difference("ShipCertification.count") do
        post project_recertifications_path(@project), params: {
          recertification_instructions: "Another attempt"
        }
      end

      assert_redirected_to project_path(@project)
      assert_equal "You already used your one post-deadline recert chance.", flash[:alert]

      # Verify user is now blocked from recerts
      assert @user.reload.has_permission?("no_recert")
    end
  end

  test "should not allow recertification if user is blocked" do
    @user.add_permission("no_recert")

    assert_no_difference("ShipCertification.count") do
      post project_recertifications_path(@project), params: {
        recertification_instructions: "Trying again"
      }
    end

    assert_redirected_to project_path(@project)
    assert_equal "Cannot request re-certification for this project.", flash[:alert]
  end

  test "should check recertification_blocked? model method" do
    refute @user.recertification_blocked?

    @user.add_permission("no_recert")
    assert @user.recertification_blocked?

    @user.remove_permission("no_recert")
    refute @user.recertification_blocked?
  end

  test "should check can_request_recertification? with blocked user" do
    assert @project.can_request_recertification?

    @user.add_permission("no_recert")
    refute @project.reload.can_request_recertification?
  end

  test "should log recertification attempts" do
    travel_to Time.zone.local(2025, 10, 3, 12, 0, 0) do
      assert_logs(nil, /recertification/i) do
        post project_recertifications_path(@project), params: {
          recertification_instructions: "Test"
        }
      end
    end
  end
end
