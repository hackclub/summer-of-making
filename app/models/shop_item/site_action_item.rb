# == Schema Information
#
# Table name: shop_items
#
#  id                         :bigint           not null, primary key
#  agh_contents               :jsonb
#  description                :string
#  enabled                    :boolean
#  enabled_au                 :boolean          default(FALSE)
#  enabled_ca                 :boolean          default(FALSE)
#  enabled_eu                 :boolean          default(FALSE)
#  enabled_in                 :boolean          default(FALSE)
#  enabled_us                 :boolean          default(FALSE)
#  enabled_xx                 :boolean          default(FALSE)
#  hacker_score               :integer          default(0)
#  hcb_category_lock          :string
#  hcb_keyword_lock           :string
#  hcb_merchant_lock          :string
#  internal_description       :string
#  limited                    :boolean          default(FALSE)
#  max_qty                    :integer          default(10)
#  name                       :string
#  one_per_person_ever        :boolean          default(FALSE)
#  price_offset_au            :decimal(6, 2)    default(0.0)
#  price_offset_ca            :decimal(6, 2)    default(0.0)
#  price_offset_eu            :decimal(6, 2)    default(0.0)
#  price_offset_in            :decimal(6, 2)    default(0.0)
#  price_offset_us            :decimal(6, 2)    default(0.0)
#  price_offset_xx            :decimal(6, 2)    default(0.0)
#  requires_black_market      :boolean
#  show_in_carousel           :boolean
#  site_action                :integer
#  stock                      :integer
#  ticket_cost                :decimal(6, 2)
#  type                       :string
#  under_the_fold_description :text
#  usd_cost                   :decimal(6, 2)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class ShopItem::SiteActionItem < ShopItem
  def self.fulfill_immediately?
    true
  end

  enum :site_action, {
    taco_bell_bong: 2,
    neon_flair: 4
  }

  def fulfill!(shop_order)
    case site_action
    when "taco_bell_bong"
      puts "bonging..."
      ActionCable.server.broadcast("shenanigans", { type: "bong", responsible_individual: shop_order.user.display_name })
    when "neon_flair"
      shop_order.user.shenanigans_state["neon_flair"] = true
      shop_order.user.save!
    else
      raise "unknown site action: #{site_action.inspect}"
    end

    shop_order.mark_fulfilled!("it is done.", nil, "System")
  end
end
