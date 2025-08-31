# == Schema Information
#
# Table name: shop_items
#
#  id                                :bigint           not null, primary key
#  agh_contents                      :jsonb
#  description                       :string
#  enabled                           :boolean
#  enabled_au                        :boolean          default(FALSE)
#  enabled_ca                        :boolean          default(FALSE)
#  enabled_eu                        :boolean          default(FALSE)
#  enabled_in                        :boolean          default(FALSE)
#  enabled_us                        :boolean          default(FALSE)
#  enabled_xx                        :boolean          default(FALSE)
#  hacker_score                      :integer          default(0)
#  hcb_category_lock                 :string
#  hcb_keyword_lock                  :string
#  hcb_merchant_lock                 :string
#  hcb_preauthorization_instructions :text
#  internal_description              :string
#  limited                           :boolean          default(FALSE)
#  max_qty                           :integer          default(10)
#  name                              :string
#  one_per_person_ever               :boolean          default(FALSE)
#  price_offset_au                   :decimal(6, 2)    default(0.0)
#  price_offset_ca                   :decimal(6, 2)    default(0.0)
#  price_offset_eu                   :decimal(6, 2)    default(0.0)
#  price_offset_in                   :decimal(6, 2)    default(0.0)
#  price_offset_us                   :decimal(6, 2)    default(0.0)
#  price_offset_xx                   :decimal(6, 2)    default(0.0)
#  requires_black_market             :boolean
#  show_in_carousel                  :boolean
#  site_action                       :integer
#  stock                             :integer
#  ticket_cost                       :decimal(6, 2)
#  type                              :string
#  under_the_fold_description        :text
#  usd_cost                          :decimal(6, 2)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
class ShopItem::BadgeItem < ShopItem
  def self.fulfill_immediately?
    true
  end

  validates :internal_description, presence: true,
            format: { with: /\A[a-z_]+\z/, message: "must be a valid badge key (lowercase letters and underscores only)" }

  def can_purchase?(user)
    badge_key = internal_description.to_sym
    return false if user.has_badge?(badge_key)
    if badge_key == :gold_verified && !user.has_badge?(:verified)
      return false
    end

    true
  end

  def prereq(user)
    badge_key = internal_description.to_sym

    if badge_key == :gold_verified && !user.has_badge?(:verified)
      "You have to get verified first!"
    elsif user.has_badge?(badge_key)
      "You already own this!"
    else
      nil
    end
  end

  def fulfill!(shop_order)
    badge_key = internal_description.to_sym

    # Verify the badge exists
    unless Badge.exists?(badge_key)
      raise "Badge '#{badge_key}' does not exist"
    end

    if badge_key == :gold_verified && !shop_order.user.has_badge?(:verified)
      raise "User must have the verified badge before purchasing the gold verified badge"
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

      f(badge_key, shop_order.user)

      # Send notification
      badge_definition = Badge.find(badge_key)
      Badge.send_badge_notification(shop_order.user, badge_key, badge_definition, backfill: false)

      Rails.logger.info("Awarded badge '#{badge_key}' to user #{shop_order.user.id} via shop purchase")
    end

    shop_order.mark_fulfilled!("Badge awarded successfully.", nil, "System")
  end

  private

  def f(badge_key, user)
    case badge_key
    when :no_fun
      Flipper.enable(:disable_sinkening_visuals, user)
      Rails.logger.info("disable_sinkening_visuals true #{user.id}")
    end
  end
end
