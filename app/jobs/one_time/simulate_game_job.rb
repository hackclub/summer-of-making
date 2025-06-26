# don't actuallly make this as a job

class OneTime::SimulateGameJob < ApplicationJob
  def perform
    # create users and projects
    20.times do |i|
      user = User.create(email: "text+#{i}@example.com")
      Project.create(name: "Project #{i}", user: user)
    end

    Project.all.each do |project|
      # vote against all other projects
      Project.all.each do |other_project|
        winner_id = [project.id, other_project.id].max
        vote = Vote.create(
          project_1: project,
          project_2: other_project,
          user: User.all.sample,
          explaination: "I like it better than #{other_project.name}",
        )
        Project.find(winner_id).won_votes << vote
        vote.save!
      end
    end

    puts "tests simulated!"

    # checks to ensure

    # Ensure votes created
    puts "Votes: #{Vote.size}"
    # some projects should have been paid out:
    puts "Payouts: #{Payout.size}"

    Project.all.order(rating: :desc).each do |project|
      puts project.name, project.rating
    end
  end
end
