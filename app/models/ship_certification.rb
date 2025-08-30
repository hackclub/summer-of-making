# == Schema Information
#
# Table name: ship_certifications
#
#  id                    :bigint           not null, primary key
#  judgement             :integer          default("pending"), not null
#  notes                 :text
#  ysws_feedback_reasons :text
#  ysws_returned_at      :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  project_id            :bigint           not null
#  reviewer_id           :bigint
#  ysws_returned_by_id   :bigint
#
# Indexes
#
#  index_ship_certifications_on_project_id                (project_id)
#  index_ship_certifications_on_project_id_and_judgement  (project_id,judgement)
#  index_ship_certifications_on_reviewer_id               (reviewer_id)
#  index_ship_certifications_on_ysws_returned_by_id       (ysws_returned_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (reviewer_id => users.id)
#  fk_rails_...  (ysws_returned_by_id => users.id)
#
class ShipCertification < ApplicationRecord
  has_paper_trail

  belongs_to :reviewer, class_name: "User", optional: true
  validates :reviewer, presence: true, unless: -> { pending? }
  belongs_to :ysws_returned_by, class_name: "User", optional: true
  belongs_to :project
  has_many :devlogs, through: :project
  has_many :shipwright_advices, class_name: "ShipwrightAdvice"
  has_one_attached :proof_video, dependent: :destroy

  after_commit :schedule_video_conversion, if: :should_convert_video?
  after_commit :schedule_judgment_notification, if: :saved_change_to_judgement?

  default_scope { joins(:project).where(projects: { is_deleted: false }) }

  enum :judgement, {
    pending: 0,
    approved: 1,
    rejected: 2
  }

  YSWS_FEEDBACK_REASONS = [
    "functionality_not_demonstrated",
    "unclear_project_demonstration",
    "technical_issues_in_video",
    "insufficient_proof_of_functionality",
    "other_certification_issues"
  ].freeze

  YSWS_FEEDBACK_REASON_LABELS = {
    "functionality_not_demonstrated" => "Functionality not clearly demonstrated",
    "unclear_project_demonstration" => "Unclear or confusing project demonstration",
    "technical_issues_in_video" => "Technical issues in the certification video",
    "insufficient_proof_of_functionality" => "Insufficient proof that project works",
    "other_certification_issues" => "Other certification-related issues"
  }.freeze

  def ysws_returned?
    ysws_returned_at.present?
  end

  def ysws_feedback_reason_list
    return [] unless ysws_feedback_reasons.present?
    JSON.parse(ysws_feedback_reasons)
  rescue JSON::ParserError
    []
  end

  def ysws_feedback_reason_labels
    ysws_feedback_reason_list.map { |reason| YSWS_FEEDBACK_REASON_LABELS[reason] }.compact
  end

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

  def schedule_judgment_notification
    old_judgment = judgement_before_last_save
    new_judgment = judgement

    # Don't notify when judgment is set to pending
    return if pending?

    # Schedule notification with 5-minute delay to prevent misclick notifications
    ShipCertificationJudgmentNotificationJob.set(wait: 5.minutes).perform_later(id, old_judgment, new_judgment)
  end
end
