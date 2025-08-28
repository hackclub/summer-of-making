class ShipCertificationJudgmentNotificationJob < ApplicationJob
  queue_as :latency_5m

  def perform(ship_certification_id, old_judgment, new_judgment)
    ship_certification = ShipCertification.find_by(id: ship_certification_id)
    return unless ship_certification

    # Verify the judgment hasn't changed again during the delay
    return unless ship_certification.judgement == new_judgment

    # Don't notify if it changed back to the old judgment
    return if ship_certification.judgement == old_judgment

    user = ship_certification.project.user
    return unless user.slack_id

    message = build_notification_message(ship_certification, new_judgment)
    SendSlackDmJob.perform_later(user.slack_id, message)
  end

  private

  def build_notification_message(ship_certification, judgment)
    project_title = ship_certification.project.title
    status = judgment.titleize

    case judgment
    when "approved"
      "🎉 Congratulations! Your ship certification for \"#{project_title}\" has been approved! You're now certified for this project."
    when "rejected"
      "Your ship certification for \"#{project_title}\" has been reviewed and requires some changes. Check the admin panel for reviewer notes and feedback."
    else
      "Your ship certification for \"#{project_title}\" status has been updated to: #{status}"
    end
  end
end
