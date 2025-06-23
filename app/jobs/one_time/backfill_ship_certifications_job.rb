class OneTime::BackfillShipCertificationsJob < ApplicationJob
  queue_as :default

  def perform
    project_ids_needing_certification = Project.joins(:ship_events)
                                               .left_joins(:ship_certifications)
                                               .where(ship_certifications: { id: nil })
                                               .distinct
                                               .pluck(:id)

    project_ids_needing_certification.each do |project_id|
      ShipCertification.create!(project_id: project_id)
    end
  end
end
