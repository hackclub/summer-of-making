# == Schema Information
#
# Table name: shop_orders
#
#  id                                 :bigint           not null, primary key
#  aasm_state                         :string
#  awaiting_periodical_fulfillment_at :datetime
#  external_ref                       :string
#  frozen_address                     :jsonb
#  frozen_item_price                  :decimal(6, 2)
#  fulfilled_at                       :datetime
#  internal_notes                     :text
#  on_hold_at                         :datetime
#  quantity                           :integer
#  rejected_at                        :datetime
#  rejection_reason                   :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  shop_item_id                       :bigint           not null
#  user_id                            :bigint           not null
#
# Indexes
#
#  index_shop_orders_on_shop_item_id  (shop_item_id)
#  index_shop_orders_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (user_id => users.id)
#
class ShopOrder < ApplicationRecord
  include AASM
  include PublicActivity::Model
  tracked only: [ :create ], owner: Proc.new { |controller, model| controller&.current_user }

  belongs_to :user
  belongs_to :shop_item

  has_many :payouts, as: :payable, dependent: :destroy

  validate :check_one_per_person_ever_limit
  validate :check_max_quantity_limit
  validate :check_black_market_access
  validate :check_user_balance
  after_create :create_negative_payout
  after_initialize :set_initial_state_for_free_stickers

  scope :worth_counting, -> {where.not(aasm_state: %w(rejected refunded))}

  def full_name
    "#{user.first_name} #{user.last_name}'s order for #{quantity} #{shop_item.name.pluralize(quantity)}"
  end

  aasm timestamps: true do # SAGA PATTERN TIME BABEY
    # NORMAL STATES: steps we'd like orders to take on their journeys

    state :pending, initial: true             # submitted, awaiting shoperations rubber-stampage
    state :awaiting_periodical_fulfillment    # waiting for one of:
    # - shop ops to order something from amazon or smth
    # - nightly warehouse coalesce job
    # - next minuteman run
    # - other "approved but waiting state"
    state :fulfilled                          # we did it reddit! nora lives another day

    # EXCEPTION STATES: sometimes things happen.

    state :rejected                           # shoperations rejected an order
    state :in_verification_limbo              # special case for free stickers
    state :on_hold                            # pending fraud investigation? or for some weird other special cases


    event :queue_for_nightly do
      transitions from: :pending, to: :awaiting_periodical_fulfillment
    end

    event :mark_rejected do
      transitions to: :rejected
      before do |rejection_reason|
        self.rejection_reason = rejection_reason
      end
    end

    event :mark_fulfilled do
      transitions to: :fulfilled
      before do |external_ref = nil|
        self.external_ref = external_ref
      end
    end

    event :place_on_hold do
      transitions to: :on_hold
    end

    event :take_off_hold do
      transitions from: :on_hold, to: :pending
    end

    event :user_was_verified do
      transitions from: :in_verification_limbo, to: :awaiting_periodical_fulfillment
      before do
        self.awaiting_periodical_fulfillment_at = Time.current
      end
    end
  end

  private

  def set_initial_state_for_free_stickers
    return unless new_record? && shop_item.is_a?(ShopItem::FreeStickers)

    if user&.ysws_verified?
      self.aasm_state = "awaiting_periodical_fulfillment"
      self.awaiting_periodical_fulfillment_at = Time.current
    else
      self.aasm_state = "in_verification_limbo"
    end
  end

  def check_one_per_person_ever_limit
    return unless shop_item&.one_per_person_ever?

    if quantity && quantity > 1
      errors.add(:quantity, "can only be 1 for #{shop_item.name} (once per person item).")
      return
    end

    existing_order = user.shop_orders.joins(:shop_item).where(shop_item: shop_item).worth_counting
    existing_order = existing_order.where.not(id: id) if persisted?

    if existing_order.exists?
      errors.add(:base, "You can only order #{shop_item.name} once per person.")
    end
  end

  def check_max_quantity_limit
    return unless shop_item&.max_qty && quantity

    if quantity > shop_item.max_qty
      errors.add(:quantity, "cannot exceed #{shop_item.max_qty} for this item.")
    end
  end

  def check_black_market_access
    return unless shop_item&.requires_black_market?

    unless user&.has_black_market?
      errors.add(:base, "This item requires black market access.")
    end
  end

  def check_user_balance
    return unless shop_item&.ticket_cost&.positive? && quantity.present?

    total_cost = shop_item.ticket_cost * quantity
    if user&.balance&.< total_cost
      shortage = total_cost - (user.balance || 0)
      errors.add(:base, "Insufficient balance. You need #{shortage} more tickets.")
    end
  end

  def create_negative_payout
    return unless frozen_item_price.present? && frozen_item_price > 0 && quantity.present?

    total_cost = frozen_item_price * quantity

    user.payouts.create!(
      amount: -total_cost,
      payable: self,
      reason: "Shop order of #{shop_item.name.pluralize(quantity)}"
    )
  end
end
