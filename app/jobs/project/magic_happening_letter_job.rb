class Project::MagicHappeningLetterJob < ApplicationJob
  queue_as :default

  def perform(project)
    return unless project&.user&.guess_address&.present?

    response = TheseusService.create_letter_v1(
      "instant/som25-magic-happening",
      {
        recipient_email: project.user.email,
        address: project.user.guess_address,
        idempotency_key: "som25_magic_project_#{project.id}",
        metadata: {
          som_user: project.user.id,
          project: project.title,
          reviewer: project.magic_reporter&.display_name
        }
      }
    )

    project.update!(magic_letter_id: response[:id])
  end
end
