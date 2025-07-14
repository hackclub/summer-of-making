class ShopItem::BadgeItem < ShopItem
  def self.fulfill_immediately?
    true
  end

  validates :internal_description, presence: true, 
            format: { with: /\A[a-z_]+\z/, message: "must be a valid badge key (lowercase letters and underscores only)" }

  def fulfill!(shop_order)
    badge_key = internal_description.to_sym
    
    # Verify the badge exists
    unless Badge.exists?(badge_key)
      raise "Badge '#{badge_key}' does not exist"
    end
    
    # Check if user already has this badge
    if shop_order.user.has_badge?(badge_key)
      Rails.logger.warn("User #{shop_order.user.id} already has badge '#{badge_key}' - skipping award")
    else
      # Award the badge directly (not through background job since this is immediate fulfillment)
      shop_order.user.user_badges.create!(
        badge_key: badge_key,
        earned_at: Time.current
      )
      
      # Send notification
      badge_definition = Badge.find(badge_key)
      Badge.send_badge_notification(shop_order.user, badge_key, badge_definition, backfill: false)
      
      Rails.logger.info("Awarded badge '#{badge_key}' to user #{shop_order.user.id} via shop purchase")
    end

    shop_order.mark_fulfilled!("Badge awarded successfully.", nil, "System")
  end
end 