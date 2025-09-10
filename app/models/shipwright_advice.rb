# == Schema Information
#
# Table name: shipwright_advices
#
#  id                    :bigint           not null, primary key
#  completed_at          :datetime
#  description           :text
#  proof_link            :string
#  shell_reward          :integer          default(0)
#  status                :integer          default("pending")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  project_id            :bigint           not null
#  ship_certification_id :bigint           not null
#
# Indexes
#
#  index_shipwright_advices_on_project_id             (project_id)
#  index_shipwright_advices_on_project_id_and_status  (project_id,status)
#  index_shipwright_advices_on_ship_certification_id  (ship_certification_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (ship_certification_id => ship_certifications.id)
#
class ShipwrightAdvice < ApplicationRecord
  belongs_to :project
  belongs_to :ship_certification

  enum :status, {
    pending: 0,
    completed: 1,
    rewarded: 2
  }

  validates :description, presence: true

  scope :for_user, ->(user) { joins(:project).where(projects: { user: user }) }

  def can_be_completed?
    pending?
  end

  def complete!
    return false unless can_be_completed?

    transaction do
      update!(
        status: :completed,
        completed_at: Time.current
      )

      # Removed payout and proof_link logic
      # Create payout for the improvement
      # Payout.create!(
      #   user: project.user,
      #   amount: shell_amount,
      #   reason: "Improvement completed for '#{project.title}': #{description.truncate(50)}",
      #   payable: self,
      #   escrowed: false
      # )

      # update!(status: :rewarded)
    end

    true
  rescue => e
    errors.add(:base, e.message)
    false
  end
end
