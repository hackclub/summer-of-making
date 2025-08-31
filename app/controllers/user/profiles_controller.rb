class User::ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_profile

  def show
    redirect_to user_path(@user)
  end

  def edit
    authorize @profile
  end

  def update
    authorize @profile

    if @profile.update(profile_params)
      redirect_to user_path(@user), notice: "Profile was successfully updated."
    else
      render :edit
    end
  end

  private

  def set_user
    @user = if params[:user_id] == "me"
      current_user
    else
      User.find(params[:user_id])
    end
  end

  def set_profile
    @profile = @user.user_profile || @user.build_user_profile
  end

  def profile_params
    params.require(:user_profile).permit(:bio, :custom_css, :hide_from_logged_out, :balloon_color)
  end
end
