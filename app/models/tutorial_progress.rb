# frozen_string_literal: true

# == Schema Information
#
# Table name: tutorial_progresses
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  step_progress :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_tutorial_progresses_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class TutorialProgress < ApplicationRecord
  belongs_to :user

  TUTORIAL_STEPS = %w[campfire explore my_projects vote shop].freeze

  after_initialize :setup_default_progress, if: :new_record?

  def complete_step!(step_name)
    return unless TUTORIAL_STEPS.include?(step_name.to_s)

    step_progress[step_name.to_s] ||= {}
    step_progress[step_name.to_s]["completed_at"] = Time.current

    check_overall_completion!

    save!
  end

  def step_completed?(step_name)
    step_progress.dig(step_name.to_s, "completed_at").present?
  end

  def completion_percentage
    completed_count = TUTORIAL_STEPS.count { |step| step_completed?(step) }
    (completed_count.to_f / TUTORIAL_STEPS.count * 100).round
  end

  def completed?
    completed_at.present?
  end

  def reset_step!(step_name)
    return unless TUTORIAL_STEPS.include?(step_name.to_s)

    step_progress[step_name.to_s] = {}
    self.completed_at = nil
    save!
  end

  def reset!
    setup_default_progress
    self.completed_at = nil
    save!
  end

  private

  def setup_default_progress
    self.step_progress = TUTORIAL_STEPS.index_with do |_step|
      {}
    end
  end

  def check_overall_completion!
    return unless TUTORIAL_STEPS.all? { |step| step_completed?(step) }

    self.completed_at = Time.current
  end
end
