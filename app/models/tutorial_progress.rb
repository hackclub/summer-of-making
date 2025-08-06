# frozen_string_literal: true

# == Schema Information
#
# Table name: tutorial_progresses
#
#  id                  :bigint           not null, primary key
#  completed_at        :datetime
#  soft_tutorial_steps :jsonb            not null
#  step_progress       :jsonb            not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :bigint           not null
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

  TUTORIAL_STEPS = %w[hackatime_connected identity_verified free_stickers_ordered].freeze
  SOFT_TUTORIAL_STEPS = %w[campfire explore my_projects vote shop todo].freeze

  after_initialize :setup_default_progress, if: :new_record?

  def complete_step!(step_name)
    return unless TUTORIAL_STEPS.include?(step_name.to_s)

    step_progress[step_name.to_s] ||= {}
    step_progress[step_name.to_s]["completed_at"] = Time.current

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

  def should_show_completion_modal?
    completed? && !user.has_clicked_completed_tutorial_modal?
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

  def complete_soft_step!(step_name)
    return unless SOFT_TUTORIAL_STEPS.include?(step_name.to_s)

    soft_tutorial_steps[step_name.to_s] ||= {}
    soft_tutorial_steps[step_name.to_s]["completed_at"] = Time.current
    save!
  end

  def soft_step_completed?(step_name)
    soft_tutorial_steps.dig(step_name.to_s, "completed_at").present?
  end

  def reset_soft_step!(step_name)
    return unless SOFT_TUTORIAL_STEPS.include?(step_name.to_s)
    soft_tutorial_steps[step_name.to_s] = {}
    save!
  end

  def reset_soft_steps!
    setup_default_soft_steps
    save!
  end

  private

  def setup_default_progress
    self.step_progress = TUTORIAL_STEPS.index_with { {} }
    setup_default_soft_steps
  end

  def setup_default_soft_steps
    self.soft_tutorial_steps = SOFT_TUTORIAL_STEPS.index_with { {} }
  end
end
