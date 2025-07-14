class Badge
  BADGES = {
    admin: {
      name: "<%= admin_tool do %>",
      flavor_text: "with great power comes great responsibility... and a ban hammer.",
      icon: "🔨",
      color: "border-dashed border-orange-500 bg-orange-500/10 text-orange-800",
      criteria: ->(user) { user.is_admin? }
    },
    verified: {
      name: "Verified",
      flavor_text: "this user is verified (i.e. gave us $8)",
      icon: "verified.png",
      color: "border-blue-500 bg-blue-500/10 text-blue-800",
      criteria: ->(user) { false }
    },
    maiden_voyage: {
      name: "Maiden Voyage",
      flavor_text: "you shipped your first project! the journey begins...",
      icon: "🚢",
      color: "border-green-500 bg-green-500/10 text-green-800",
      criteria: ->(user) { user.ship_events.count >= 1 }
    },
    i_am_rich: {
      name: "I Am Rich",
      flavor_text: "you are rich. you deserv it. you are good, healthy & successful.",
      icon: "i_am_rich.png",
      color: "border-red-500 bg-red-500/10 text-red-800",
      full_size_icon: true,
      criteria: ->(user) { false }
    },
    ballot_stuffer: {
      name: "Ballot Stuffer",
      flavor_text: "vote 100 times.",
      icon: "i_voted.png",
      color: "border-green-500 bg-green-500/10 text-green-800",
      criteria: ->(user) { user.votes.count >= 100 }
    },
    graphic_design_is_my_passion: {
      name: "Graphic Design is My Passion",
      flavor_text: "Oh God How Did This Get Here I Am Not Good With Computer",
      icon: "🎨",
      color: "border-pink-500 bg-pink-500/10 text-pink-800",
      criteria: ->(user) { false } # Badge must be granted manually
    },
    sunglasses: {
      name: "Sunglasses",
      flavor_text: "protect your eyes from other people's... creative... CSS choices.",
      icon: "sunglasses.png",
      color: "border-gray-500 bg-gray-500/10 text-gray-800",
      criteria: ->(user) { false } # Badge must be granted manually
    }
  }.freeze

  def self.all
    BADGES
  end

  def self.find(key)
    BADGES[key.to_sym]
  end

  def self.exists?(key)
    BADGES.key?(key.to_sym)
  end

  def self.award_badges_for(user, backfill: false)
    newly_earned = []

    BADGES.each do |badge_key, badge_definition|
      next if user.user_badges.exists?(badge_key: badge_key)

      if badge_definition[:criteria].call(user)
        user.user_badges.create!(
          badge_key: badge_key,
          earned_at: Time.current
        )
        newly_earned << badge_key

        # Send Slack DM notification
        send_badge_notification(user, badge_key, badge_definition, backfill: backfill)
      end
    end

    newly_earned
  end

  def self.earned_by(user)
    user.user_badges.includes(:user).map do |user_badge|
      {
        key: user_badge.badge_key,
        earned_at: user_badge.earned_at,
        **BADGES[user_badge.badge_key.to_sym]
      }
    end
  end

  def self.send_badge_notification(user, badge_key, badge_definition, backfill: false)
    return unless user.slack_id.present?

    message = if backfill
      case badge_key
      when :admin
        "🔨 *ADMIN BADGE AWARDED*\n\nYou've been granted the admin badge on Summer of Making. #{badge_definition[:flavor_text]}\n\nCheck out your badge on your profile: #{profile_url(user)}"
      when :verified
        "✅ *VERIFIED BADGE AWARDED*\n\nYou've been awarded the verified badge on Summer of Making. #{badge_definition[:flavor_text]}\n\nYour badge is now visible on your profile: #{profile_url(user)}"
      when :maiden_voyage
        "🚢 *MAIDEN VOYAGE BADGE AWARDED*\n\nYou've been awarded the maiden voyage badge for shipping your first project - #{badge_definition[:flavor_text]}\n\nSee your badge here: #{profile_url(user)}"
      else
        "🏆 *BADGE AWARDED*\n\nYou've been awarded the #{badge_definition[:name]} badge! #{badge_definition[:flavor_text]}\n\nCheck it out on your profile: #{profile_url(user)}"
      end
    else
      case badge_key
      when :admin
        "🔨 *ADMIN BADGE EARNED!*\n\nCongratulations! You've been granted admin powers on Summer of Making. #{badge_definition[:flavor_text]}\n\nCheck out your new badge on your profile: #{profile_url(user)}"
      when :verified
        "✅ *VERIFIED BADGE PURCHASED!*\n\nNice! You're now verified on Summer of Making. #{badge_definition[:flavor_text]}\n\nYour shiny new badge is waiting on your profile: #{profile_url(user)}"
      when :maiden_voyage
        "🚢 *MAIDEN VOYAGE BADGE EARNED!*\n\nAhoy! You've shipped your first project - #{badge_definition[:flavor_text]}\n\nSee your achievement badge here: #{profile_url(user)}"
      else
        "🏆 *NEW BADGE EARNED!*\n\nYou've earned the #{badge_definition[:name]} badge! #{badge_definition[:flavor_text]}\n\nCheck it out on your profile: #{profile_url(user)}"
      end
    end

    SendSlackDmJob.perform_later(user.slack_id, message)
  end

  private

  def self.profile_url(user)
    Rails.application.routes.url_helpers.user_url(user, host: ENV.fetch("APP_HOST", "summer.hackclub.com"))
  end
end
