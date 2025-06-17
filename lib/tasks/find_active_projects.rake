# frozen_string_literal: true

namespace :projects do
  desc "Find projects with more than 10 devlogs spread across at least 5 different dates"
  task find_active: :environment do
    active_project_ids = Project.joins(:devlogs)
                                .group("projects.id")
                                .having("COUNT(devlogs.id) > 10")
                                .having("COUNT(DISTINCT DATE(devlogs.created_at)) >= 5")
                                .pluck("projects.id")

    active_projects = Project.where(id: active_project_ids).includes(:devlogs)

    puts "\nFound #{active_projects.count} active projects:\n\n"

    active_projects.each do |project|
      devlog_dates = project.devlogs.map { |u| u.created_at.to_date }.uniq.sort
      puts "Project: #{project.title}"
      puts "Total devlogs: #{project.devlogs.count}"
      puts "Unique devlog dates: #{devlog_dates.count}"
      puts "Devlog dates: #{devlog_dates.join(', ')}"
      puts "----------------------------------------\n"
    end
  end

  desc "DM authors of active projects to ship their projects"
  task dm_active_authors: :environment do
    active_project_ids = Project.joins(:devlogs)
                                .group("projects.id")
                                .having("COUNT(devlogs.id) > 10")
                                .having("COUNT(DISTINCT DATE(devlogs.created_at)) >= 5")
                                .pluck("projects.id")

    active_projects = Project.where(id: active_project_ids).includes(:devlogs, :user)

    puts "\nSending DMs to authors of #{active_projects.count} active projects:\n\n"

    active_projects.each do |project|
      next if project.user.slack_id.blank?

      message = "Heya! You're receiving this DM because your project fulfills the primary criteria to be eligible for the giftcard. However, for your project to enter matchmaking, you need to ship it! Just click the Ship button on https://summer.hackclub.com/my_projects and make sure everything is valid. Then you're good to go"
      SendSlackDmJob.perform_later(project.user.slack_id, message)
      puts "Sent DM to #{project.user.display_name} about project: #{project.title}"
    end
  end
end
