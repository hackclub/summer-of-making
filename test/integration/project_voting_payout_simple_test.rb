# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "rails/test_help"

class ProjectVotingSimpleTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    # Clean up any existing data to ensure clean test state
    Vote.destroy_all if defined?(Vote)
    ShipEvent.destroy_all if defined?(ShipEvent)
    Devlog.destroy_all if defined?(Devlog)
    ShipCertification.destroy_all if defined?(ShipCertification)
    HackatimeStat.destroy_all if defined?(HackatimeStat)
    Project.destroy_all if defined?(Project)
    User.destroy_all if defined?(User)
  end

  test "complete project voting simulation with fuzzing" do
    # Create users and projects (similar to SimulateGameJob)
    users = []
    projects = []
    
    10.times do |i|
      user = User.create!(
        email: "test+#{i}@example.com",
        slack_id: "U#{i.to_s.rjust(9, '0')}",
        display_name: "Test User #{i}",
        timezone: "America/New_York",
        avatar: "https://example.com/avatar#{i}.png",
        has_hackatime: true
      )
      
      # Create hackatime_stat for the user with mock data
      HackatimeStat.create!(
        user: user,
        last_updated_at: 1.hour.ago,
        data: {
          "data" => {
            "projects" => [
              {
                "name" => "test-project-#{i}",
                "total_seconds" => 3600
              }
            ]
          }
        }
      )
      
      project = Project.create!(
        title: "Project #{i}", 
        description: "Test project #{i} for integration testing",
        category: "Web App",
        user: user,
        hackatime_project_keys: ["test-project-#{i}"]  # Add hackatime keys
      )
      users << user
      projects << project
    end

    # Create 1-hour dev logs for each project
    projects.each_with_index do |project, i|
      # Create a temporary file for attachment since it's required
      file_content = "# Dev Log #{i}\n\nWorked on project for 1 hour today."
      temp_file = Tempfile.new(['devlog', '.md'])
      temp_file.write(file_content)
      temp_file.rewind
      
      # Create devlog with file attached first
      devlog = Devlog.new(
        user: project.user,
        project: project,
        text: "Worked on #{project.title} for 1 hour today. Made good progress!",
        seconds_coded: 3600,  # 1 hour in seconds
        last_hackatime_time: 3600  # Set hackatime field to bypass validation
      )
      devlog.file.attach(
        io: temp_file,
        filename: "devlog_#{i}.md",
        content_type: 'text/markdown'
      )
      devlog.save!
      temp_file.close
      temp_file.unlink
    end

    # Create ship events for each project right before voting
    projects.each do |project|
      ShipEvent.create!(project: project)
    end

    # Simulate voting between all projects (skip self-comparisons for now)
    projects.each do |project|
      projects.each do |other_project|
        # Skip self-comparisons since they may be allowed in current implementation
        next if project.id == other_project.id
        
        # Create votes with random users and mostly deterministic winners (with 10% fuzz)
        # Higher ID project usually wins, but 10% chance for upset
        if rand < 0.1
          winner_id = [project.id, other_project.id].min  # Upset: lower ID wins
        else
          winner_id = [project.id, other_project.id].max  # Expected: higher ID wins
        end
        
        vote = Vote.create!(
          project_1: project,
          project_2: other_project,
          user: users.sample,
          explanation: "I like it better than #{other_project.title}",
          winning_project_id: winner_id
        )
      end
    end

    # Trigger payouts for all projects after voting is complete
    projects.each do |project|
      project.pay_out
    end

    # Assertions to verify the system works
    assert Vote.count > 0, "Votes should have been created"
    assert Devlog.count == 10, "Dev logs should have been created"
    assert ShipEvent.count == 10, "Ship events should have been created"
    
    # Check that projects have ratings and they've drifted from default
    projects.each(&:reload)
    ratings = projects.map(&:rating).compact
    assert ratings.any?, "Projects should have ratings"
    
    min_rating = ratings.min
    max_rating = ratings.max
    rating_spread = max_rating - min_rating
    assert rating_spread >= 100, "Rating spread should be at least 100 (got #{rating_spread})"

    # Verify mostly deterministic ordering - since voting is mostly deterministic with 10% fuzz,
    # projects should generally be ordered by name when sorted by rating (higher ID = higher rating)
    ordered_projects = Project.all.order(rating: :desc)
    expected_name_order = projects.sort_by { |p| p.title.match(/\d+/)[0].to_i }.reverse.map(&:title)
    actual_name_order = ordered_projects.map(&:title)
    
    # With 10% fuzz, the ordering might not be perfectly deterministic, so we'll just check that the top project is one of the high-numbered ones
    top_project_number = ordered_projects.first.title.match(/\d+/)[0].to_i
    assert top_project_number >= 7, "Top rated project should usually be Project 7, 8, or 9 (got Project #{top_project_number})"
    
    puts "\nProject Rankings with Payouts:"
    ordered_projects.each_with_index do |project, index|
      total_payouts = project.ship_events.joins(:payouts).sum('payouts.amount')
      puts "#{index + 1}. #{project.title} - Rating: #{project.rating} - Payouts: $#{total_payouts}"
    end

    puts "\nUser Payout Summary:"
    User.all.each do |user|
      total_user_payouts = user.projects.joins(ship_events: :payouts).sum('payouts.amount')
      puts "#{user.display_name}: $#{total_user_payouts}"
    end

    puts "\nTest Summary:"
    puts "Users created: #{User.count}"
    puts "Projects created: #{Project.count}"
    puts "Dev logs created: #{Devlog.count}"
    puts "Ship events created: #{ShipEvent.count}"
    puts "Votes created: #{Vote.count}"
    total_payouts = Payout.sum(&:amount)
    puts "Total payouts: $#{total_payouts}"
  end
end
