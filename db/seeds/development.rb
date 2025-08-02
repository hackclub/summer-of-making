# frozen_string_literal: true

require "faker"
require_relative "mock_shop_items"

puts "Loading development data..."

def random_user_props
  has_name = [ true, false ].sample # some users don't share their full names
  hackatime_status = [ true, false ].sample

  {
    slack_id: "U#{Faker::Alphanumeric.alphanumeric(number: 10).upcase}",
    email: Faker::Internet.unique.email,
    first_name: has_name ? Faker::Name.first_name : nil,
    last_name: has_name ? Faker::Name.last_name : nil,
    display_name: Faker::Internet.unique.username,
    timezone: Faker::Address.time_zone,
    has_hackatime: hackatime_status,
    has_hackatime_account: hackatime_status,
    has_commented: [ true, false ].sample,
    ysws_verified: [ true, false ].sample,
    tutorial_video_seen: [ true, false ].sample,
    has_clicked_completed_tutorial_modal: [ true, false ].sample,
    avatar: Faker::Avatar.image(slug: SecureRandom.hex(10), size: "192x192", format: "png", set: "any", bgset: "any")
  }
end

puts "(1/9) Creating users..."
50.times do
  User.create!(random_user_props)
end

puts "(2/9) Creating admins..."
10.times do
  User.create!(
    {
      **random_user_props,
      is_admin: true,
      ysws_verified: true,
      tutorial_video_seen: true,
      has_clicked_completed_tutorial_modal: true
    }
  )
end

def random_project_category
  [ "Web App", "Mobile App", "Command Line Tool", "Video Game", "Something else" ].sample
end

def random_project_props
  username = Faker::Internet.username
  repo_slug = Faker::Internet.slug
  is_on_map = [ true, false ].sample

  {
    title: Faker::App.name,
    description: Faker::Lorem.paragraphs(number: 3).join("\n\n"),
    used_ai: [ true, false ].sample,
    category: random_project_category,
    x: is_on_map ? rand(0.0..100.0) : nil,
    y: is_on_map ? rand(0.0..100.0) : nil,
    readme_link: "https://github.com/#{username}/#{repo_slug}/blob/main/README.md",
    demo_link: Faker::Internet.url,
    repo_link: "https://github.com/#{username}/#{repo_slug}",
    rating: rand(718..1404),
    certification_type: rand(0..12), # see project.rb:141 for more details
    views_count: rand(0..2000),
    hackatime_project_keys: [ Faker::Internet.slug ]
  }
end

linked_users = User.where(has_hackatime: true)
ship_eligible_users = User.where(ysws_verified: true, has_hackatime: true)

puts "(3/9) Retrieving dummy stock images..."

DUMMY_IMAGE_COUNT = 15

DUMMY_IMAGES = []
DUMMY_IMAGE_COUNT.times do |i|
  image_url = "https://picsum.photos/seed/devlog#{i}/#{rand(300..2000)}/#{rand(300..2000)}"
  DUMMY_IMAGES << URI.open(image_url)

  puts "  #{i + 1} out of #{DUMMY_IMAGE_COUNT} images downloaded"
end

def get_dummy_image
  io = DUMMY_IMAGES.sample.dup
  io.rewind
  io
end

puts "(4/9) Creating verified projects..."
150.times do
  project = Project.create!(
    {
      **random_project_props,
      user: ship_eligible_users.sample,
      is_shipped: true
    }
  )

  project.banner.attach(
    io: get_dummy_image,
    filename: "image#{SecureRandom.hex(10)}.jpg",
    content_type: "image/jpeg"
  )
  project.save!

  ShipCertification.create!(
    project: project,
    reviewer_id: User.where(is_admin: true).first&.id || User.first.id,
    judgement: 1, # approved
    notes: Faker::Lorem.sentence
  )
end

puts "(5/9) Creating unverified projects..."
50.times do
  props = random_project_props

  Project.create!(
    {
      **props,
      readme_link: [ props[:readme_link], nil ].sample,
      demo_link: [ props[:demo_link], nil ].sample,
      repo_link: [ props[:repo_link], nil ].sample,
      rating: 1100, # default rating for unshipped projects
      is_shipped: false,
      user: linked_users.sample
    }
  )
end

puts "(6/9) Creating devlogs..."
Project.all.each do |project|
  next unless project.user.has_hackatime

  rand(1..5).times do
    seconds = rand(3600..21600)

    devlog = Devlog.new(
      text: [
        Faker::TvShows::SiliconValley.quote,
        Faker::Lorem.paragraphs(number: rand(2..5)).join("\n\n"),
        Faker::Markdown.sandwich
      ].sample,
      user: project.user,
      project: project,
      seconds_coded: seconds,
      likes_count: rand(0..50),
      comments_count: 0,
      views_count: rand(0..200),
      duration_seconds: seconds,
      last_hackatime_time: seconds  # Set hackatime field to bypass validation
    )

    devlog.file.attach(
      io: get_dummy_image,
      filename: "image#{SecureRandom.hex(10)}.jpg",
      content_type: "image/jpeg"
    )
    devlog.save!

    if rand < 0.3
      rand(1..3).times do
        Comment.create!(
          user: User.where.not(id: devlog.user_id).sample,
          devlog: devlog,
          content: [
            Faker::Lorem.paragraphs(number: rand(2..5)).join("\n\n"),
            Faker::Hacker.say_something_smart
          ].sample,
          rich_content: {
            type: "doc",
            content: [
              {
                type: "paragraph",
                content: [
                  {
                    type: "text",
                    text: Faker::Lorem.paragraph
                  }
                ]
              }
            ]
          }
        )
      end

      devlog.update_column(:comments_count, devlog.comments.count)
    end
  end

  # We create ship events here, because they have to be made AFTER the devlogs to actually
  # appear in the vote page.
  if project.is_shipped
    ShipEvent.create(project: project)
  end
end

puts "(7/9) Creating project follows..."
Project.all.each do |project|
  User.all.sample(rand(0..10)).each do |user|
    ProjectFollow.create!(user: user, project: project) unless user == project.user
  end
end

puts "(8/9) Creating likes..."
Devlog.all.each do |devlog|
  User.all.sample(rand(0..10)).each do |user|
    Like.create!(user: user, likeable: devlog)
  end
end

puts "(9/9) Creating shop items..."

MockShopItems::SHOP_ITEMS.each do |item_data|
  ShopItem.create(name: item_data[:name]) do |item|
    item.type = item_data[:type]
    item.description = item_data[:description]
    item.internal_description = item_data[:internal_description]
    item.ticket_cost = item_data[:ticket_cost]
    item.usd_cost = item_data[:usd_cost]
    item.hacker_score = item_data[:hacker_score]
    item.requires_black_market = false
    item.one_per_person_ever = item_data[:one_per_person_ever]
    item.show_in_carousel = item_data[:show_in_carousel]
    item.enabled = true
    item.enabled_au = rand < 0.8
    item.enabled_ca = rand < 0.8
    item.enabled_eu = rand < 0.9
    item.enabled_in = rand < 0.8
    item.enabled_us = rand < 0.8
    item.enabled_xx = rand < 0.5

    item.image.attach(io: get_dummy_image, filename: "image#{SecureRandom.hex(10)}.jpg")
  end
end

puts "Seed data creation completed!"
