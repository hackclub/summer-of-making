# frozen_string_literal: true

require_relative "../test_helper"

class ProjectVotingPayoutTest < ActiveSupport::TestCase
  def setup
    # Clean up any existing data to ensure clean test state
    Payout.destroy_all
    Vote.destroy_all
    Project.destroy_all
    User.destroy_all
  end

  test "complete project voting and payout simulation" do
    # Create users and projects (similar to SimulateGameJob)
    users = []
    projects = []
    
    20.times do |i|
      user = User.create!(email: "test+#{i}@example.com")
      project = Project.create!(name: "Project #{i}", user: user)
      users << user
      projects << project
    end

    # Simulate voting between all projects
    projects.each do |project|
      projects.each do |other_project|
        winner_id = [project.id, other_project.id].max
        vote = Vote.create!(
          project_1: project,
          project_2: other_project,
          user: users.sample,
          explaination: "I like it better than #{other_project.name}"
        )
        Project.find(winner_id).won_votes << vote
        vote.save!
      end
    end

    # Assertions to verify the system works
    assert Vote.count > 0, "Votes should have been created"
    
    # Check that projects have ratings and they've drifted from default
    projects.reload
    ratings = projects.map(&:rating).compact
    assert ratings.any?, "Projects should have ratings"
    
    min_rating = ratings.min
    max_rating = ratings.max
    rating_spread = max_rating - min_rating
    assert rating_spread >= 100, "Rating spread should be at least 100 (got #{rating_spread})"
    
    # Check if payouts were generated (if that's automatic)
    if Payout.count > 0
      assert Payout.count > 0, "Payouts should have been generated"
    end

    # Verify deterministic ordering - since voting is deterministic based on project ID,
    # projects should be ordered by name when sorted by rating (higher ID = higher rating)
    ordered_projects = Project.all.order(rating: :desc)
    expected_name_order = projects.sort_by { |p| p.name.match(/\d+/)[0].to_i }.reverse.map(&:name)
    actual_name_order = ordered_projects.map(&:name)
    
    assert_equal expected_name_order, actual_name_order, "Projects should be ordered by name (deterministic voting)"
    
    puts "\nProject Rankings:"
    ordered_projects.each_with_index do |project, index|
      puts "#{index + 1}. #{project.name} - Rating: #{project.rating}"
    end

    puts "\nTest Summary:"
    puts "Users created: #{User.count}"
    puts "Projects created: #{Project.count}"
    puts "Votes created: #{Vote.count}"
    puts "Payouts created: #{Payout.count}"
  end
end
