# == Schema Information
#
# Table name: fraud_reports
#
#  id               :bigint           not null, primary key
#  category         :string
#  reason           :string
#  resolved         :boolean          default(FALSE), not null
#  resolved_at      :datetime
#  resolved_message :text
#  resolved_outcome :string
#  suspect_type     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  resolved_by_id   :bigint
#  suspect_id       :bigint
#  user_id          :bigint           not null
#
# Indexes
#
#  index_fraud_reports_on_category                (category)
#  index_fraud_reports_on_resolved_by_id          (resolved_by_id)
#  index_fraud_reports_on_suspect_and_resolution  (suspect_type,suspect_id,resolved_at)
#  index_fraud_reports_on_user_and_suspect        (user_id,suspect_type,suspect_id) UNIQUE
#  index_fraud_reports_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (resolved_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#
class FraudReport < ApplicationRecord
  has_paper_trail

  belongs_to :suspect, polymorphic: true
  belongs_to :reporter, class_name: "User", foreign_key: "user_id"
  belongs_to :resolver, class_name: "User", foreign_key: "resolved_by_id", optional: true

  validates :user_id, uniqueness: { scope: [ :suspect_type, :suspect_id ], message: "You have already reported this project" }

  scope :resolved, -> { where(resolved: true) }
  scope :unresolved, -> { where(resolved: false) }
  scope :low_quality_category, -> {
    where("(category = ?) OR (reason LIKE ?)", "low_quality", "LOW_QUALITY:%")
  }

  def self.already_reported_by?(user, suspect)
    exists?(
      user_id: user.id,
      suspect_type: suspect.class.name,
      suspect_id: suspect.id
    )
  end

  def resolve!(user: nil, outcome: nil, message: nil)
    update!(resolved: true, resolved_at: Time.current, resolved_by_id: user&.id, resolved_outcome: outcome, resolved_message: message)
  end

  def unresolve!
    update!(resolved: false, resolved_at: nil, resolved_by_id: nil)
  end
end
