module Admin
  class SinkeningController < ApplicationController
    def show
      @setting = SinkeningSetting.current
    end

    def update
      @setting = SinkeningSetting.current

      if @setting.update(intensity: params[:intensity], slack_story_url: params[:slack_story_url])
        flash[:success] = "Sinkening settings updated. Intensity: #{@setting.intensity}"
      else
        flash[:error] = "Failed to update intensity: #{@setting.errors.full_messages.join(', ')}"
      end

      redirect_to admin_sinkening_path
    end
  end
end
