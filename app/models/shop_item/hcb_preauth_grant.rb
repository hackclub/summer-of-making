# == Schema Information
#
# Table name: shop_items
#
#  id                                :bigint           not null, primary key
#  advent_announced                  :boolean          default(FALSE), not null
#  agh_contents                      :jsonb
#  campfire_only                     :boolean          default(TRUE), not null
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
#  sale_percentage                   :integer
#  show_in_carousel                  :boolean
#  site_action                       :integer
#  special                           :boolean          default(FALSE), not null
#  stock                             :integer
#  ticket_cost                       :decimal(6, 2)
#  type                              :string
#  under_the_fold_description        :text
#  unlock_on                         :date
#  usd_cost                          :decimal(6, 2)
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#
# Indexes
#
#  idx_shop_items_enabled_black_market_price  (enabled,requires_black_market,ticket_cost)
#  idx_shop_items_regional_enabled            (enabled,enabled_us,enabled_eu,enabled_in,enabled_ca,enabled_au,enabled_xx)
#  idx_shop_items_type_enabled                (type,enabled)
#  index_shop_items_on_unlock_on              (unlock_on)
#
class ShopItem::HCBPreauthGrant < ShopItem
  after_save :enqueue_hcb_locks_update, if: :hcb_locks_changed?

  has_many :shop_card_grants, through: :shop_orders

  def fulfill!(shop_order)
    amount_cents = (usd_cost * shop_order.quantity * 100).to_i
    email = shop_order.user.email
    merchant_lock = hcb_merchant_lock
    keyword_lock = hcb_keyword_lock
    category_lock = hcb_category_lock

    # Create a new grant for each order - no find_or_create_by
    grant_rec = ShopCardGrant.new(
      user: shop_order.user,
      shop_item: self
    )

    grant_rec.transaction do
      Rails.logger.info "Creating preauth grant for #{email} of #{amount_cents} cents"

      grant_response = HCBService.create_card_grant(
        email: email,
        amount_cents: amount_cents,
        merchant_lock: merchant_lock,
        keyword_lock: keyword_lock,
        category_lock: category_lock,
        purpose: "SOM: #{name}",
        instructions: hcb_preauthorization_instructions
      )

      grant_rec.hcb_grant_hashid = grant_response["id"]
      grant_rec.expected_amount_cents = amount_cents
      grant_rec.save!

      latest_disbursement = grant_response.dig("disbursements", 0, "transaction_id")
      memo = "[preauth grant] #{name} for #{shop_order.user.display_name}"

      Rails.logger.info "Got disbursement: #{latest_disbursement}"

      # Update shop order to reference the card grant
      shop_order.shop_card_grant = grant_rec
      shop_order.mark_fulfilled! "SCG #{grant_rec.id}", nil, "System"

      # Try to rename the transaction
      if latest_disbursement
        begin
          HCBService.rename_transaction(hashid: latest_disbursement, new_memo: memo)
        rescue => e
          Rails.logger.error "Couldn't rename transaction #{latest_disbursement}: #{e.message}"
        end
      end
    end

    grant_rec
  end

  private

  def hcb_locks_changed?
    type == "ShopItem::HCBPreauthGrant" &&
      saved_change_to_hcb_merchant_lock? ||
      saved_change_to_hcb_keyword_lock? ||
      saved_change_to_hcb_category_lock
  end

  def enqueue_hcb_locks_update
    Shop::UpdateHCBLocksJob.perform_later(id)
  end
end
