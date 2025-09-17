class StaticPagesController < ApplicationController
  def gork
    redirect_to root_path, alert: "come back when you're a little....richer." unless current_user&.verified_check?
  end

  def s
    token = SecretThirdThing.dejigimaflip(current_user.id)
    @iframe_src = "#{SecretThirdThing.base_url}/scenes/"
    @iframe_src << "#{params[:scene]}/" if params[:scene].present?
    @iframe_src << "?login_token=#{token}"
    render layout: false
  end
end
