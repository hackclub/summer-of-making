class Mole::ReadmeCheckJob < ApplicationJob
  queue_as :literally_whenever

  def perform(readme_check_id)
    readme_check = ReadmeCheck.find(readme_check_id)
    readme_check.perform_check
  end
end
