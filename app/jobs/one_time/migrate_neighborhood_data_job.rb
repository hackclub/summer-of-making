class OneTime::MigrateNeighborhoodDataJob < ApplicationJob
  queue_as :default

  def perform(dry_run = true, slack_id = nil)
    ActiveRecord::Base.transaction do
      pull_data

      pull_user_specific_data(slack_id) if slack_id.present?

      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  def pull_data
    @transfers = cache_with_json("transfers_all.json") do
      cached_records_from("Post Event - Hour Transfers").map { |r| r&.fields }
    end
    @transfers_for_som = cache_with_json("transfers_for_som.json") do
      @transfers.select { |r| r["Which transfer option would you like to go with?"] == "Summer of Making"}
    end
    puts "found #{@transfers_for_som.count} hour transfers"
    slack_ids_for_som = @transfers_for_som.map { |r| r["What is your Slack ID?"] }.compact.uniq

    filter_for_neighbors = slack_ids_for_som.map{ |slack_id| "{Slack ID (from slackNeighbor)}='#{slack_id}'" }
    @neighbors = cache_with_json("neighbors.json") do
      cached_records_from("neighbors", filter: "OR(#{filter_for_neighbors.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{@neighbors.count} neighbors"

    # argh! turns out these don't exist. neighborhood was tracking projects in a
    # way that associated multiple people together for group projects, so we
    # can't split them out using this the Apps or YSWS Project Submission tables

    # filter_for_projects = slack_ids_for_som.map{ |slack_id| "{Slack ID (from slackNeighbor) (from neighbors)}='#{slack_id}'" }
    # projects = cache_with_json("projects.json") do
    #   cached_records_from("YSWS Project Submission", filter: "OR(#{filter_for_projects.join(", ")})").map { |r| r&.fields }
    # end
    # puts "found #{projects.count} projects"

    # these are like devlogs
    filter_for_posts = slack_ids_for_som.map{ |slack_id| "{slackId}='#{slack_id}'" }
    @posts = cache_with_json("posts.json") do
      cached_records_from("Posts", filter: "OR(#{filter_for_posts.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{@posts.count} posts"
  end

  def pull_user_specific_data(slack_id)
    neighbor = @neighbors.find { |n| n["Slack ID (from slackNeighbor)"].first == slack_id }

    puts "found neighbor for slack_id #{slack_id}: #{neighbor.inspect}"

    return unless neighbor


    # check they have a user
    if User.find_by_slack_id(slack_id).nil?
      puts "no user found for slack_id #{slack_id}, creating!"
    else
      puts "user found! no generation needed"
    end

  end

  def cache_with_json(cache_name, &block)
    cache_path = Rails.root.join("tmp", cache_name)
    unless File.exist?(cache_path)
      results = block.call
      export_to_json(results, cache_path)
    end
    JSON.parse(File.read(cache_path))
  end

  def export_to_json(records, filename)
    File.open(filename, "w") do |file|
      file.write(JSON.pretty_generate(records))
    end
  end

  def table(table_name)
    Norairrecord.table(
      ENV['NEIGHBORHOOD_AIRTABLE_KEY'],
      "appnsN4MzbnfMY0ai",
      table_name
    )
  end

  def cached_records_from(table_name, filter: nil)
    # jk, no caching for now
    table(table_name).all(filter: filter)
  end
end
