# frozen_string_literal: true

class BrainrotController < ApplicationController
  before_action :authenticate_user!
  before_action :check_brainrot_feature_enabled

  # API endpoint to check brainrot status
  def status
    render json: {
      active: brainrot_mode_active?,
      config: brainrot_config
    }
  end

  # API endpoint to get random brainrot sound
  def random_sound
    sounds = brainrot_config[:sounds]
    random_sound = sounds.sample

    render json: {
      sound_url: random_sound,
      sounds_count: sounds.length
    }
  end

  private

  def check_brainrot_feature_enabled
    return if Flipper.enabled?(:brainrot_mode, current_user)

    render json: { error: "Brainrot mode is not enabled" }, status: :forbidden
  end
end