# == Schema Information
#
# Table name: ship_certifications
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
#  index_ship_certifications_on_project_id                (project_id)
#  index_ship_certifications_on_project_id_and_judgement  (project_id,judgement)
#  index_ship_certifications_on_reviewer_id               (reviewer_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (reviewer_id => users.id)
#
class ShipCertification < ApplicationRecord
  belongs_to :reviewer, class_name: "User", optional: true
  validates :reviewer, presence: true, unless: -> { pending? }
  belongs_to :project
  has_one_attached :proof_video, dependent: :destroy

  after_commit :schedule_video_conversion, if: :should_convert_video?

  default_scope { joins(:project).where(projects: { is_deleted: false }) }

  enum :judgement, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  private

  def should_convert_video?
    return false unless proof_video.attached?

    content_type = proof_video.content_type
    !content_type&.include?("mp4") && !content_type&.include?("webm")
  end

  def schedule_video_conversion
    Rails.logger.info "Scheduling video conversion for ShipCertification #{id}"
    VideoConversionJob.perform_unique(id)
  end
end
