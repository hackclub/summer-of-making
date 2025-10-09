# == Schema Information
#
# Table name: payouts
#
#  id           :bigint           not null, primary key
#  amount       :decimal(6, 2)
#  escrowed     :boolean          default(FALSE), not null
#  payable_type :string
#  reason       :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  payable_id   :bigint
#  user_id      :bigint           not null
#
# Indexes
#
#  index_payouts_on_created_at             (created_at)
#  index_payouts_on_created_at_and_amount  (created_at,amount)
#  index_payouts_on_date_type_amount       (created_at,payable_type,amount)
#  index_payouts_on_escrowed               (escrowed)
#  index_payouts_on_payable                (payable_type,payable_id)
#  index_payouts_on_payable_type           (payable_type)
#  index_payouts_on_user_id                (user_id)
#
class Payout < ApplicationRecord
  # NOTE Aug 23, 2025 IST: Escrow is deprecated for new payouts.
  belongs_to :payable, polymorphic: true
  belongs_to :user

  validates_presence_of :amount

  before_validation :set_user_id

  scope :escrowed, -> { where(escrowed: true) }
  scope :released, -> { where(escrowed: false) }

  VOTE_COUNT_REQUIRED = 10

  after_create_commit :broadcast_ship_payout_balloon

  # x = ELO percentile (0-1)
  def self.calculate_multiplier(x)
    t = 0.5; a = 10.0 # Between the minimum and maximum ELO scores, a project with the ELO score at point T between these points (you know what t-values are) will get the multiplier A. So when T = 0.5 and A = 10, the average multiplier is 10.
    n = 1.0 # The minimum payout multiplier
    m = 30.0 # The maximum payout multiplier

    # https://hc-cdn.hel1.your-objectstorage.com/s/v3/e179f7f9d9a1e440d332590200fedae6401f9be6_image.png
    exp = Math.log((a-n) / (m-n), t)
    n + (((2.0*x-1.0) * Math.sqrt(2.0 * (1.0 - ((2.0*x-1.0)**2.0 / 2.0))) + 1.0) / 2.0) ** exp * (m-n)
  end

  private

  def set_user_id
    self.user ||= payable.is_a?(User) ? payable : payable.user
  end

  def broadcast_ship_payout_balloon
    return unless payable_type == "ShipEvent" && escrowed == false

    project = payable.project
    hours = payable.hours_covered
    mult = hours.to_f > 0 ? (amount.to_f / hours.to_f).round(1) : 0
    ActionCable.server.broadcast "balloons", {
      type: "ShipPayout",
      href: Rails.application.routes.url_helpers.project_url(project, only_path: true),
      color: project.user.user_profile&.balloon_color || %w[#b00b69 #69b00b #d90ba7 #1ffffa].sample,
      tagline: ERB::Util.html_escape("Paid #{project.title}: #{amount.to_i} shells (#{hours.round(1)}h × #{mult}x)")
    }
  end
end
