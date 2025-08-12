# == Schema Information
#
# Table name: fraud_reports
#
#  id           :bigint           not null, primary key
#  reason       :string
#  resolved     :boolean          default(FALSE), not null
#  suspect_type :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  suspect_id   :bigint
#  user_id      :bigint           not null
#
# Indexes
#
#  index_fraud_reports_on_user_and_suspect  (user_id,suspect_type,suspect_id) UNIQUE
#  index_fraud_reports_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class FraudReport < ApplicationRecord
  has_paper_trail

  belongs_to :suspect, polymorphic: true
  belongs_to :reporter, class_name: "User", foreign_key: "user_id"

  validates :user_id, uniqueness: { scope: [ :suspect_type, :suspect_id ], message: "You have already reported this project" }

  scope :resolved, -> { where(resolved: true) }
  scope :unresolved, -> { where(resolved: false) }

  def self.already_reported_by?(user, suspect)
    exists?(
      user_id: user.id,
      suspect_type: suspect.class.name,
      suspect_id: suspect.id
    )
  end

  def resolve!
    update!(resolved: true)
  end

  def unresolve!
    update!(resolved: false)
  end
end
