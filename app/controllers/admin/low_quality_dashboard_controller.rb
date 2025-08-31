module Admin
  class LowQualityDashboardController < ApplicationController
    before_action :authenticate_ship_certifier!
    skip_before_action :authenticate_admin!

    def index
      @threshold = 1
      @state = params[:state].presence_in([ "resolved", "unresolved" ]) || "unresolved"

      base = FraudReport.low_quality_category
      base = @state == "resolved" ? base.resolved : base.unresolved

      proj_counts = base.where(suspect_type: "Project").group(:suspect_id).count
      se_counts = base.where(suspect_type: "ShipEvent").group(:suspect_id).count
      se_project_map = ShipEvent.where(id: se_counts.keys).pluck(:id, :project_id).to_h
      rolled = se_counts.each_with_object(Hash.new(0)) { |(se_id, count), h| h[se_project_map[se_id]] += count }
      merged = proj_counts.merge(rolled) { |_, a, b| a + b }
      @reported = merged.select { |_, c| c >= @threshold }

      project_ids = @reported.keys.compact
      @projects = Project.where(id: project_ids).includes(:user, :ship_events)

      # get all reasons
      @project_reports = {}
      project_ids.each do |project_id|
        project_reports = base.where(suspect_type: "Project", suspect_id: project_id).includes(:reporter)
        ship_reports = base.joins("JOIN ship_events ON ship_events.id = fraud_reports.suspect_id").where(ship_events: { project_id: project_id }).includes(:reporter)

        all_reports = project_reports.to_a + ship_reports.to_a
        @project_reports[project_id] = all_reports.sort_by(&:created_at)
      end
    end

    def mark_low_quality
      project = Project.find(params[:project_id])
      reason = params[:reason]

      if reason.blank?
        redirect_to admin_low_quality_dashboard_index_path, alert: "Reason is required when marking as low quality."
        return
      end

      # minimum payout only if no payout exists for latest ship
      ship = project.ship_events.order(:created_at).last
      if ship.present? && ship.payouts.none?
        hours = ship.hours_covered
        min_multiplier = 1.0
        amount = (min_multiplier * hours).ceil
        if amount > 0
          Payout.create!(amount: amount, payable: ship, user: project.user, reason: "Minimum payout (low-quality)", escrowed: false)
        end
      end

      FraudReport.where(suspect_type: "Project", suspect_id: project.id, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "low_quality", resolved_message: reason)
      FraudReport.where(suspect_type: "ShipEvent").joins("JOIN ship_events ON ship_events.id = fraud_reports.suspect_id").where(ship_events: { project_id: project.id }, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "low_quality", resolved_message: reason)

      if project.user&.slack_id.present?
        message = <<~EOT
        Thanks for shipping! After review, this ship didn't meet our voting quality bar.

        **Shipwright Feedback:** #{reason}

        We issued a minimum payout if there wasn't already one. Keep building – you can ship again anytime.
        EOT
        SendSlackDmJob.perform_later(project.user.slack_id, message)
      end

      redirect_to admin_low_quality_dashboard_index_path, notice: "Marked as low-quality and handled payouts/DMs."
    end

    def mark_ok
      project = Project.find(params[:project_id])
      ok_reason = params[:ok_reason].to_s.presence
      FraudReport.where(suspect_type: "Project", suspect_id: project.id, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "ok", resolved_message: ok_reason)
      FraudReport.where(suspect_type: "ShipEvent").joins("JOIN ship_events ON ship_events.id = fraud_reports.suspect_id").where(ship_events: { project_id: project.id }, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "ok", resolved_message: ok_reason)

      redirect_to admin_low_quality_dashboard_index_path, notice: "Marked OK and cleared reports."
    end

    private

    def authenticate_ship_certifier!
      redirect_to root_path unless current_user&.admin_or_ship_certifier?
    end
  end
end
