# == Schema Information
#
# Table name: readme_certifications
#
#  id          :bigint           not null, primary key
#  judgement   :integer          default("pending"), not null
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  project_id  :bigint           not null
#  reviewer_id :bigint
#
# Indexes
#
#  index_readme_certifications_on_project_id                (project_id)
#  index_readme_certifications_on_project_id_and_judgement  (project_id,judgement)
#  index_readme_certifications_on_reviewer_id               (reviewer_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id) ON DELETE => cascade
#  fk_rails_...  (reviewer_id => users.id) ON DELETE => nullify
#
class ReadmeCertification < ApplicationRecord
  belongs_to :reviewer, class_name: "User", optional: true
  validates :reviewer, presence: true, unless: -> { pending? }
  belongs_to :project

  default_scope { joins(:project).where(projects: { is_deleted: false }) }

  enum :judgement, {
    pending: 0,
    approved: 1,
    rejected: 2
  }
end
