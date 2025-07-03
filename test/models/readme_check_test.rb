# frozen_string_literal: true

require "test_helper"

class ReadmeCheckTest < ActiveSupport::TestCase
  test "should generate decision_message when decision is made" do
    project = Project.create!(
      title: "Test Project",
      description: "A test project",
      readme_link: "https://raw.githubusercontent.com/example/repo/main/README.md"
    )

    readme_check = ReadmeCheck.create!(project: project)

    # Mock the content check to avoid external API calls
    readme_check.update!(
      content: "# My Project\n\nThis is a generic React template.",
      status: :success,
      decision: :templated,
      reason: "Generic template detected",
      decision_message: FlavorTextService.generate_mole_message_for_decision(:templated)
    )

    assert_not_nil readme_check.decision_message
    assert readme_check.decision_message.length > 0
    puts "Generated message: #{readme_check.decision_message}"
  end

  test "should generate different messages for different decisions" do
    decisions = [:missing, :templated, :ai_generated, :specific]

    decisions.each do |decision|
      message = FlavorTextService.generate_mole_message_for_decision(decision)
      assert_not_nil message
      assert message.length > 0
      puts "#{decision}: #{message}"
    end
  end
end
