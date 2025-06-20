# frozen_string_literal: true

# == Schema Information
#
# Table name: shop_items
#
#  id                         :bigint           not null, primary key
#  agh_contents               :jsonb
#  description                :string
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
#  stock                      :integer
#  ticket_cost                :decimal(6, 2)
#  type                       :string
#  under_the_fold_description :text
#  usd_cost                   :decimal(6, 2)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
class ShopItem::HCBGrant < ShopItem
  after_save :enqueue_hcb_locks_update, if: :hcb_locks_changed?

  has_many :shop_card_grants, through: :shop_orders
  def fulfill!(shop_order)
    amount_cents = (usd_cost * shop_order.quantity * 100).to_i
    email = shop_order.user.email
    merchant_lock = hcb_merchant_lock
    keyword_lock = hcb_keyword_lock
    category_lock = hcb_category_lock

    # Find or create ShopCardGrant for this user and item
    grant_rec = ShopCardGrant.find_or_initialize_by(
      user: shop_order.user,
      shop_item: self
    )

    user_canceled = false
    latest_disbursement = nil
    memo = nil

    grant_rec.transaction do
      begin
        if grant_rec.new_record? || user_canceled
          # Create new grant
          Rails.logger.info "Creating grant for #{email} of #{amount_cents} cents"

          grant_response = HCBService.create_card_grant(
            email: email,
            amount_cents: amount_cents,
            merchant_lock: merchant_lock,
            keyword_lock: keyword_lock,
            category_lock: category_lock,
            purpose: "SOM: #{name}"
          )

          grant_rec.hcb_grant_hashid = grant_response["id"]
          grant_rec.expected_amount_cents = amount_cents
          grant_rec.save!

          latest_disbursement = grant_response.dig("disbursements", 0, "transaction_id")
          memo = "[grant] #{name} for #{shop_order.user.display_name}"
        else
          # Top up existing grant
          hashid = grant_rec.hcb_grant_hashid

          # Check if grant is still active
          begin
            hcb_grant = HCBService.show_card_grant(hashid: hashid)
            if hcb_grant["status"] == "canceled"
              user_canceled = true
              raise StandardError, "Grant canceled"
            end
          rescue => e
            Rails.logger.error "Error checking grant status: #{e.message}"
            user_canceled = true
            raise StandardError, "Grant canceled"
          end

          Rails.logger.info "Topping up #{hashid} by #{amount_cents} cents"

          topup_response = HCBService.topup_card_grant(
            hashid: hashid,
            amount_cents: amount_cents
          )

          latest_disbursement = topup_response.dig("disbursements", 0, "transaction_id")
          grant_rec.expected_amount_cents = (grant_rec.expected_amount_cents || 0) + amount_cents
          grant_rec.save!

          memo = "[grant] topping up #{shop_order.user.display_name}'s #{name}"
        end

        Rails.logger.info "Got disbursement: #{latest_disbursement}"

      rescue => e
        if user_canceled
          Rails.logger.info "Grant was canceled, retrying with new grant"
          user_canceled = true
          retry
        else
          raise e
        end
      end
    end

    # Update shop order to reference the card grant
    shop_order.shop_card_grant = grant_rec
    shop_order.mark_fulfilled! "SCG #{grant_rec.id}"

    # Try to rename the transaction
    if latest_disbursement
      begin
        HCBService.rename_transaction(hashid: latest_disbursement, new_memo: memo)
      rescue => e
        Rails.logger.error "Couldn't rename transaction #{latest_disbursement}: #{e.message}"
      end
    end

    grant_rec
  end

  private

  def hcb_locks_changed?
    type == "ShopItem::HCBGrant" &&
      saved_change_to_hcb_merchant_lock? ||
      saved_change_to_hcb_keyword_lock? ||
      saved_change_to_hcb_category_lock
  end

  def enqueue_hcb_locks_update
    Shop::UpdateHCBLocksJob.perform_later(id)
  end
end
