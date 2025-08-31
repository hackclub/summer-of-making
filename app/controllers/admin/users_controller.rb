module Admin
  class UsersController < ApplicationController
    include Pagy::Backend
    before_action :ensure_authorized_user
    before_action :set_user, except: [ :index ]
    skip_before_action :authenticate_admin!

    def index
      @pagy, @users = pagy(
        User
          .all
          .search(params[:search]&.sub("mailto:", ""))
          .order(id: :desc),
        items: 50)
    end

    def show
      user_activities = @user.activities
      project_activities = PublicActivity::Activity.where(trackable: @user.projects.with_deleted)

      @activities = PublicActivity::Activity.where(id: user_activities.pluck(:id) + project_activities.pluck(:id))
                                            .order(created_at: :desc)
                                            .includes(:owner, :trackable)
      @payouts = @user.payouts.order(created_at: :desc).includes(:payable)

      @user = User.includes(
        :user_hackatime_data,
        :tutorial_progress,
        :projects,
        :devlogs,
        :votes,
        :followed_projects,
        :staked_projects,
        :shop_orders,
        :shop_card_grants,
        :hackatime_projects
      ).find(params[:id])

      @hackatime_id = fetch_hackatime(@user.email)

      @flipper_flags = Flipper.features
    end

    def internal_notes
      @user.internal_notes = params[:internal_notes]
      @user.create_activity("edit_internal_notes", params: { note: params[:internal_notes] })
      @user.save!
      render :internal_notes, layout: false
    end

    def create_payout
      parameters = payout_params
      if parameters[:amount].to_f > 9999
        return redirect_to(admin_user_path(@user), notice: "fuck you trying to do? cause inflation? thats too much at once!")
      end
      unless parameters[:reason].present?
        return redirect_to(admin_user_path(@user), notice: "Please provide a reason!")
      end
      @payout = @user.payouts.build(parameters.merge(payable: @user, escrowed: false))

      begin
        @payout.save!
        @user.create_activity("manual_payout", parameters:)
        flash[:success] = "Successfully created payout!"
        redirect_to admin_user_path(@user)
      rescue ActiveRecord::RecordInvalid => e
        redirect_to admin_user_path, notice: e.message
      end
    end

    def nuke_idv_data
      @user.nuke_idv_data!
      flash[:success] = "what have you done"
      redirect_to admin_user_path(@user)
    end

    def cancel_card_grants
      CancelUserCardGrantsJob.perform_later(@user)
      @user.create_activity("cancel_card_grants")
      flash[:success] = "Card grant cancellation job has been queued"
      redirect_to admin_user_path(@user)
    end

    def freeze
      @user.update!(freeze_shop_activity: true)
      @user.create_activity("freeze")
      flash[:success] = "they are now entombed icily!"
      redirect_to admin_user_path(@user)
    end

    def defrost
      @user.update!(freeze_shop_activity: false)
      @user.create_activity("defrost")
      flash[:success] = "please let them thaw for a few hours..."
      redirect_to admin_user_path(@user)
    end

    def give_black_market
      @user.give_black_market!
      @user.create_activity("give_black_market")
      flash[:success] = "they're in!"
      redirect_back_or_to admin_user_path(@user)
    end

    def take_away_black_market
      @user.update!(has_black_market: false)
      @user.create_activity("take_away_black_market")
      flash[:success] = "unfortunate."
      redirect_to admin_user_path(@user)
    end

    def grant_ship_certifier
      if @user.ship_certifier?
        flash[:notice] = "#{@user.email} nothing changed, they already have ship certifier permissions"
      else
        @user.add_permission("shipcert")
        @user.create_activity("grant_ship_certifier")
        flash[:success] = "gotcha, granted rights to #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    def revoke_ship_certifier
      unless @user.ship_certifier?
        flash[:notice] = "#{@user.email} nothing changed, they don't have ship certifier permissions"
      else
        @user.remove_permission("shipcert")
        @user.create_activity("revoke_ship_certifier")
        flash[:success] = "gotcha, revoked rights from #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    def ban_user
      @user.ban_user!("admin_ban")
      flash[:success] = "get rekt"
      redirect_to admin_user_path(@user)
    end

    def unban_user
      @user.unban_user!
      flash[:success] = "//undoing"
      redirect_to admin_user_path(@user)
    end

    def flip
      if params[:state] == "true"
        Flipper.enable_actor(params[:flag], @user)
      else
        Flipper.disable_actor(params[:flag], @user)
      end
      @user.create_activity("flip", params: { flag: params[:flag], state: params[:state] })
      flash[:success] = "gotcha, flipped #{params[:flag]} to #{params[:state]}"
      redirect_to admin_user_path(@user)
    end

    def impersonate
      unless current_user&.is_admin?
        Honeybadger.notify("what the h-e-double-hockey-sticks?")
        return redirect_to root_path
      end
      if @user == current_user
        flash[:notice] = "that's you, bozo!"
        return redirect_back_or_to admin_user_path(@user)
      end
      session[:impersonator_user_id] ||= current_user.id
      @user.create_activity("impersonate")
      session[:user_id] = @user.id
      flash[:success] = "hey #{@user.display_name}! how's it going? nice 'stache and glasses!"
      redirect_to root_path
    end

    def set_hackatime_trust_factor
      trust_params = trust_factor_params
      trust_level = trust_params[:trust_level]
      reason = trust_params[:reason]
      api_key = trust_params[:api_key]

      unless trust_level.present? && reason.present? && api_key.present?
        flash[:error] = "you gotta fill everything out silly head"
        return redirect_to admin_user_path(@user)
      end

      hackatime_id = fetch_hackatime(@user.email)
      unless hackatime_id
        flash[:error] = "could not find that person!"
        return redirect_to admin_user_path(@user)
      end

      begin
        headers = {
          "Authorization" => "Bearer #{api_key}",
          "Content-Type" => "application/json"
        }

        payload = {
          id: hackatime_id.to_s,
          trust_level: trust_level,
          reason: reason
        }

        response = Faraday.post(
          "https://hackatime.hackclub.com/api/admin/v1/user/convict",
          payload.to_json,
          headers
        )

        if response.success?
          trust_level_name = case trust_level.to_i
          when 0 then "blue (unscored)"
          when 1 then "red (convicted)"
          when 2 then "green (trusted)"
          when 3 then "yellow (suspected)"
          else "unknown"
          end

          flash[:success] = "Successfully set trust level to #{trust_level_name}"
        else
          error_message = begin
            error_body = JSON.parse(response.body)
            error_body["error"] || error_body["message"] || response.body
          rescue JSON::ParserError
            response.body
          end

          flash[:error] = "#{error_message}"
        end
      rescue => e
        Rails.logger.error("ruh ro, failed to do that #{e.message}")
        Honeybadger.notify(e, context: { user_id: @user.id, trust_level: trust_level, reason: reason })
        flash[:error] = "error! #{e.message}"
      end
      redirect_to admin_user_path(@user)
    end

    def refresh_hackatime
      begin
        @user.refresh_hackatime_data_now
        flash[:success] = "your wish is my command"
      rescue => e
        Honeybadger.notify(e, context: { user_id: @user.id })
        flash[:error] = "failed manual refresh ht #{e.message}"
      end
      redirect_to admin_user_path(@user)
    end

    def grant_fraud_reviewer
      if @user.fraud_team_member?
        flash[:notice] = "#{@user.email} nothing changed, they already have fraud reviewer permissions"
      else
        @user.update!(fraud_team_member: true)
        @user.create_activity("grant_fraud_reviewer")
        flash[:success] = "gotcha, granted fraud reviewer rights to #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    def revoke_fraud_reviewer
      unless @user.fraud_team_member?
        flash[:notice] = "#{@user.email} nothing changed, they don't have fraud reviewer permissions"
      else
        @user.update!(fraud_team_member: false)
        @user.create_activity("revoke_fraud_reviewer")
        flash[:success] = "gotcha, revoked fraud reviewer rights from #{@user.email}"
      end
      redirect_to admin_user_path(@user)
    end

    private

    def ensure_authorized_user
      unless current_user&.is_admin? || current_user&.fraud_team_member?
        redirect_to root_path, alert: "whomp whomp"
      end
    end

    def fetch_hackatime(email)
      return nil if email.blank?

      begin
        headers = {
          "Authorization" => ENV.fetch("HACKATIME_AUTH_TOKEN"),
          "RACK_ATTACK_BYPASS" => ENV.fetch("HACKATIME_BYPASS_KEYS")
        }.compact

        res = Faraday.get(
          "https://hackatime.hackclub.com/api/v1/users/lookup_email/#{email}",
          nil,
          headers
        )

        if res.success?
          data = JSON.parse(res.body)
          data["user_id"]
        elsif res.status == 404
          nil
        else
          Rails.logger.warn("Hackatime lookup failed for #{email}")
          Honeybadger.notify("Hackatime lookup failed", context: { email: email, status: res.status })
          nil
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Hackatime JSON parse error")
        Honeybadger.notify(e, context: { email: email })
        nil
      rescue => e
        Rails.logger.error("Hackatime lookup error")
        Honeybadger.notify(e, context: { email: email })
        nil
      end
    end

    def set_user
      @user = User.find(params[:id])
    end

    def payout_params
      params.require(:payout).permit(:amount, :reason)
    end

    def trust_factor_params
      params.permit(:trust_level, :reason, :api_key)
    end
  end
end
