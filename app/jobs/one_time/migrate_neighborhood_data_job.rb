class OneTime::MigrateNeighborhoodDataJob < ApplicationJob
  require "set"
  require "net/http"
  require "uri"
  require "stringio"

  queue_as :default

  def perform(dry_run = true, slack_id = nil)
    ActiveRecord::Base.transaction do
      pull_data

      if slack_id
        import_data_for(slack_id)
      else
        import_data_for_all_users
      end

      raise ActiveRecord::Rollback if dry_run
    end
  end

  def import_only(dry_run = true, slack_id = nil)
    ActiveRecord::Base.transaction do
      if slack_id
        import_data_for(slack_id)
      else
        import_data_for_all_users
      end

      raise ActiveRecord::Rollback if dry_run
    end
  end

  private

  def pull_data
    transfers = cache_with_json("transfers_all.json") do
      cached_records_from("Post Event - Hour Transfers").map { |r| r&.fields }
    end

    transfers_for_som = cache_with_json("transfers_for_som.json") do
      transfers.select { |r| r["Which transfer option would you like to go with?"] == "Summer of Making" }
    end
    puts "found #{transfers_for_som.count} hour transfers"

    slack_ids_for_som = transfers_for_som.map { |r| r["What is your Slack ID?"] }.compact.uniq
    puts "found #{slack_ids_for_som.count} users who transferred to SoM"

    filter_for_neighbors = slack_ids_for_som.map { |slack_id| "{Slack ID (from slackNeighbor)}='#{slack_id}'" }
    neighbors = cache_with_json("neighbors.json") do
      cached_records_from("neighbors", filter: "OR(#{filter_for_neighbors.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{neighbors.count} neighbors"

    filter_for_projects = slack_ids_for_som.map { |slack_id| "{Slack ID (from slackNeighbor) (from neighbors)}='#{slack_id}'" }
    projects = cache_with_json("projects.json") do
      cached_records_from("YSWS Project Submission", filter: "OR(#{filter_for_projects.join(", ")})").map { |r| { "id" => r&.id, "fields" => r&.fields } }
    end
    puts "found #{projects.count} projects"

    # linked app records mess :pf: i hate airtable
    app_record_ids = projects.map { |project| project&.dig("fields", "app") }.flatten.compact.uniq
    puts "found #{app_record_ids.count} linked app records"

    # these are like devlogs
    filter_for_posts = slack_ids_for_som.map { |slack_id| "{slackId}='#{slack_id}'" }
    posts = cache_with_json("posts.json") do
      cached_records_from("Posts", filter: "OR(#{filter_for_posts.join(", ")})").map { |r| r&.fields }
    end
    puts "found #{posts.count} posts"

    if app_record_ids.any?
      filter_for_apps = app_record_ids.map { |app_id| "RECORD_ID()='#{app_id}'" }
      apps = cache_with_json("apps.json") do
        cached_records_from("Apps", filter: "OR(#{filter_for_apps.join(", ")})").map { |r| { "id" => r&.id, "fields" => r&.fields } }
      end
      puts "found #{apps.count} app records"
    else
      puts "no linked apps to fetch"
    end
  end

  def import_data_for(slack_id)
    puts "Importing data for user: #{slack_id}"

    transfers_for_som = JSON.parse(File.read("/tmp/transfers_for_som.json"))
    posts = JSON.parse(File.read("/tmp/posts.json"))
    apps = File.exist?("/tmp/apps.json") ? JSON.parse(File.read("/tmp/apps.json")) : []

    migrate_existing_user_devlogs(posts, apps, [ slack_id ])
  end

  def import_data_for_all_users
    puts "Importing data for all users..."

    transfers_for_som = JSON.parse(File.read("/tmp/transfers_for_som.json"))
    posts = JSON.parse(File.read("/tmp/posts.json"))
    apps = File.exist?("/tmp/apps.json") ? JSON.parse(File.read("/tmp/apps.json")) : []

    slack_ids_for_som = transfers_for_som.map { |r| r["What is your Slack ID?"] }.compact.uniq
    migrate_existing_user_devlogs(posts, apps, slack_ids_for_som)
  end

  def migrate_existing_user_devlogs(posts, apps, slack_ids_for_som)
    processed_count = 0
    skipped_users = 0
    unique_missing_projects = Set.new
    created_devlogs = 0

    slack_ids_for_som.each do |slack_id|
      user = User.find_by(slack_id: slack_id)

      unless user
        puts "User #{slack_id} not found in system, skipping"
        skipped_users += 1
        next
      end

      puts "Processing user #{slack_id} (#{user.email})"

      # posts = devlogs
      user_posts = posts.select { |post| post["slackId"]&.include?(slack_id) }
      puts "  Found #{user_posts.count} devlogs for user"

      user_posts.each do |post_data|
        # search by title
        app_name = post_data["appName"]&.first
        next unless app_name

        project = user.projects.find_by(title: app_name)

        unless project
          puts "  Project '#{app_name}' not found for user #{slack_id}, skipping devlog #{post_data["ID"]}"
          unique_missing_projects.add("#{slack_id}:#{app_name}")
          next
        end

        raw_hackatime_projects = post_data["app__hackatimeProjects__names"] || []
        filtered_hackatime_projects = raw_hackatime_projects.reject { |key| key == "<<LAST_PROJECT>>" || key == "Other" }

        project.hackatime_project_keys = filtered_hackatime_projects
        project.save!

        post_created_at = Time.parse(post_data["createdAt"]) if post_data["createdAt"]
        text = post_data["description"]
        hackatime_projects = filtered_hackatime_projects

        devlog = project.devlogs.build(
          user: user,
          text: text,
          duration_seconds: 0, # We'll re-calculate this later. I just want to set this to 0 for now
          created_at: post_created_at,
          hackatime_projects_key_snapshot: hackatime_projects,
          is_neighborhood_migrated: true
        )

        # download and attach video
        if post_data["demoVideo"]
          download_and_attach_video(post_data["demoVideo"], devlog)
        end

        devlog.save!(validate: false)

        puts "  Created devlog for post #{post_data["ID"]} in project '#{project.title}'"
        created_devlogs += 1
      end

      processed_count += 1
    end
    # AI-generated summary
    puts "\nMigration Summary:"
    puts "  Users processed: #{processed_count}"
    puts "  Users skipped (not found): #{skipped_users}"
    puts "  Unique user:project combinations not found: #{unique_missing_projects.size}"
    puts "  Devlogs created: #{created_devlogs}"
  end

  def cache_with_json(cache_name, &block)
    cache_path = File.join("/tmp", cache_name)
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
      ENV["NEIGHBORHOOD_AIRTABLE_KEY"],
      "appnsN4MzbnfMY0ai",
      table_name
    )
  end

  def cached_records_from(table_name, filter: nil)
    # jk, no caching for now
    table(table_name).all(filter: filter)
  end

  def download_and_attach_video(video_url, devlog)
    return nil unless video_url.present?

    begin
      response = fetch_video(video_url)
    rescue => e
      puts "Failed to download from #{video_url}: #{e.message}"

      # fallback, because migration from aws to r2 failed - thomas
      if video_url.include?("juice.hackclub-assets.com")
        fallback_url = video_url.gsub("juice.hackclub-assets.com", "hc-juice.s3.amazonaws.com")
        puts "Trying fallback URL: #{fallback_url}"

        begin
          response = fetch_video(fallback_url)
        rescue => fallback_error
          puts "Fallback also failed: #{fallback_error.message}"
          return nil
        end
      else
        return nil
      end
    end

    filename = File.basename(URI.parse(video_url).path)
    filename = "demo_video.mp4" if filename.blank? || !filename.include?(".")

    # active storage - use cloudflare r2
    devlog.file.attach(
      io: StringIO.new(response.body),
      filename: filename,
      content_type: response.content_type || "video/mp4",
      service_name: :cloudflare
    )

    puts "Successfully attached video: #{filename}"
    devlog
  rescue => e
    puts "Error processing video #{video_url}: #{e.message}"
    nil
  end

  def fetch_video(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    http.read_timeout = 30
    http.open_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    if response.code.to_i == 404
      raise "Video not found (404)"
    elsif !response.code.start_with?("2")
      raise "HTTP error: #{response.code} #{response.message}"
    end

    response
  end
end
