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
      @projects = Project.where(id: project_ids).includes(:user, ship_events: :payouts).to_a

      @latest_ship_by_project = {}
      @latest_ship_has_payout = {}
      @projects.each do |project|
        latest_ship = project.ship_events.max_by(&:created_at)
        @latest_ship_by_project[project.id] = latest_ship
        @latest_ship_has_payout[project.id] = latest_ship.present? && latest_ship.payouts.any?
      end

      # srt so projects with NO payout on latest ship appear first, then by report count desc
      @projects.sort_by! do |project|
        [ (@latest_ship_has_payout[project.id] ? 1 : 0), -(@reported[project.id] || 0) ]
      end

      # get all reasons
      @project_reports = {}
      project_ids.each do |project_id|
        project_reports = base.where(suspect_type: "Project", suspect_id: project_id).includes(:reporter)
        ship_reports = base.joins("JOIN ship_events ON ship_events.id = fraud_reports.suspect_id").where(ship_events: { project_id: project_id }).includes(:reporter)

        all_reports = project_reports.to_a + ship_reports.to_a
        @project_reports[project_id] = all_reports.sort_by(&:created_at)
      end

      # Add analytics data
      calculate_analytics_data
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
      issued_min_payout = false
      if ship.present? && ship.payouts.none?
        hours = ship.hours_covered
        min_multiplier = 1.0
        amount = (min_multiplier * hours).ceil
        if amount > 0
          Payout.create!(amount: amount, payable: ship, user: project.user, reason: "Minimum payout (low-quality)", escrowed: false)
          issued_min_payout = true
        end
      end

      FraudReport.where(suspect_type: "Project", suspect_id: project.id, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "low_quality", resolved_message: reason)
      FraudReport.where(suspect_type: "ShipEvent").joins("JOIN ship_events ON ship_events.id = fraud_reports.suspect_id").where(ship_events: { project_id: project.id }, resolved: false).update_all(resolved: true, resolved_at: Time.current, resolved_by_id: current_user.id, resolved_outcome: "low_quality", resolved_message: reason)

      if project.user&.slack_id.present?
        parts = []
        parts << "Thanks for shipping! After review, this ship didn't meet our voting quality bar."
        parts << "Shipwright Feedback: #{reason}"
        parts << "We issued a minimum payout since there wasn't already one." if issued_min_payout
        parts << "Keep building – you can ship again anytime."
        SendSlackDmJob.perform_later(project.user.slack_id, parts.join("\n\n"))
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

    def message_repeat_offender
      user = User.find(params[:user_id])
      message = params[:message]

      if message.blank?
        redirect_to admin_low_quality_dashboard_index_path, alert: "Message content is required."
        return
      end

      if user.slack_id.present?
        formatted_message = "Hi #{user.display_name || 'there'}! This is a message from the Shipwright team:\n\n#{message}\n\nKeep building amazing things!"
        SendSlackDmJob.perform_later(user.slack_id, formatted_message)
        redirect_to admin_low_quality_dashboard_index_path, notice: "Message sent to #{user.display_name}."
      else
        redirect_to admin_low_quality_dashboard_index_path, alert: "User doesn't have a Slack ID configured."
      end
    end

    private

    def calculate_analytics_data
      # Time periods for comparison
      @current_week_start = 7.days.ago
      @last_week_start = 14.days.ago
      @current_month_start = 30.days.ago
      @last_month_start = 60.days.ago

      calculate_volume_metrics
      calculate_resolution_metrics
      calculate_efficiency_metrics
      calculate_impact_metrics
      calculate_trend_data
    end

    def calculate_volume_metrics
      # Reports coming in this week vs last week
      @reports_current_week = FraudReport
        .where(created_at: @current_week_start..Time.current)
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .count

      @reports_last_week = FraudReport
        .where(created_at: @last_week_start..@current_week_start)
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .count

      @reports_current_month = FraudReport
        .where(created_at: @current_month_start..Time.current)
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .count

      @reports_last_month = FraudReport
        .where(created_at: @last_month_start..@current_month_start)
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .count

      # Week over week and month over month change
      @wow_change = calculate_percentage_change(@reports_last_week, @reports_current_week)
      @mom_change = calculate_percentage_change(@reports_last_month, @reports_current_month)

      # Total unresolved cases currently requiring attention
      proj_counts = FraudReport.unresolved
        .where(suspect_type: "Project")
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .group(:suspect_id)
        .count

      se_counts = FraudReport.unresolved
        .where(suspect_type: "ShipEvent")
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .group(:suspect_id)
        .count

      se_project_map = ShipEvent.where(id: se_counts.keys).pluck(:id, :project_id).to_h
      rolled = se_counts.each_with_object(Hash.new(0)) { |(se_id, count), h| h[se_project_map[se_id]] += count }
      merged = proj_counts.merge(rolled) { |_, a, b| a + b }

      @current_cases_needing_attention = merged.select { |_, c| c >= @threshold }.count
      @total_unresolved_reports = merged.values.sum
    end

    def calculate_resolution_metrics
      # Cases resolved this week/month
      resolved_reports = FraudReport.resolved.where("reason LIKE ?", "LOW_QUALITY:%")

      @resolved_current_week = resolved_reports
        .where(updated_at: @current_week_start..Time.current)
        .count

      @resolved_current_month = resolved_reports
        .where(updated_at: @current_month_start..Time.current)
        .count

      # Average time to resolution
      resolved_with_time = resolved_reports
        .where(updated_at: @current_month_start..Time.current)
        .where.not(created_at: nil)

      if resolved_with_time.any?
        total_resolution_time = resolved_with_time.sum { |report| report.updated_at - report.created_at }
        @avg_resolution_time_hours = (total_resolution_time / resolved_with_time.count) / 3600.0
      else
        @avg_resolution_time_hours = 0
      end

      # Resolution rate (resolved vs new reports this month)
      new_reports_month = FraudReport
        .where(created_at: @current_month_start..Time.current)
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .count

      @resolution_rate = new_reports_month > 0 ? (@resolved_current_month.to_f / new_reports_month * 100).round(1) : 0
    end

    def calculate_efficiency_metrics
      # Track which admins are handling cases (based on PaperTrail versions)
      resolved_reports = FraudReport.resolved
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .where(updated_at: @current_month_start..Time.current)

      @admin_resolution_counts = {}

      resolved_reports.find_each do |report|
        # Try to get the last version that marked it as resolved
        # Use JSONB operator to check for 'resolved' key changes
        versions = report.versions.where("object_changes ? 'resolved'").order(:created_at)
        last_resolver_version = versions.last

        if last_resolver_version && last_resolver_version.whodunnit
          resolver_id = last_resolver_version.whodunnit.to_i
          resolver = User.find_by(id: resolver_id)
          if resolver
            resolver_name = resolver.display_name || resolver.email
            @admin_resolution_counts[resolver_name] ||= 0
            @admin_resolution_counts[resolver_name] += 1
          end
        else
          @admin_resolution_counts["Unknown"] ||= 0
          @admin_resolution_counts["Unknown"] += 1
        end
      end

      @admin_resolution_counts = @admin_resolution_counts.sort_by { |_, count| -count }.to_h
    end

    def calculate_impact_metrics
      # Low quality payouts issued (minimum payouts from mark_low_quality action)
      @low_quality_payouts_count = Payout
        .where(reason: "Minimum payout (low-quality)")
        .where(created_at: @current_month_start..Time.current)
        .count

      @low_quality_payouts_total = Payout
        .where(reason: "Minimum payout (low-quality)")
        .where(created_at: @current_month_start..Time.current)
        .sum(:amount)

      # Projects marked as low quality vs marked OK
      low_quality_marked = Payout
        .where(reason: "Minimum payout (low-quality)")
        .where(created_at: @current_month_start..Time.current)
        .count

      total_resolved = FraudReport.resolved
        .where("reason LIKE ?", "LOW_QUALITY:%")
        .where(updated_at: @current_month_start..Time.current)
        .distinct
        .count("CASE WHEN suspect_type = 'Project' THEN suspect_id ELSE (SELECT project_id FROM ship_events WHERE ship_events.id = fraud_reports.suspect_id LIMIT 1) END")

      @marked_low_quality = low_quality_marked
      @marked_ok = [ total_resolved - low_quality_marked, 0 ].max

      # Repeat offenders (users with multiple low quality reports)
      project_user_map = Project.pluck(:id, :user_id).to_h
      ship_event_project_map = ShipEvent.joins(:project).pluck(:id, :project_id).to_h

      user_report_counts = Hash.new(0)

      FraudReport.where("reason LIKE ?", "LOW_QUALITY:%")
        .where(created_at: @current_month_start..Time.current)
        .find_each do |report|
          user_id = case report.suspect_type
          when "Project"
            project_user_map[report.suspect_id]
          when "ShipEvent"
            project_id = ship_event_project_map[report.suspect_id]
            project_user_map[project_id] if project_id
          end

          user_report_counts[user_id] += 1 if user_id
        end

      @repeat_offenders = user_report_counts.select { |_, count| count > 1 }
      @repeat_offenders_data = @repeat_offenders.map do |user_id, count|
        user = User.find_by(id: user_id)
        {
          user: user,
          report_count: count,
          display_name: user&.display_name || "Unknown User"
        }
      end.sort_by { |data| -data[:report_count] }
    end

    def calculate_trend_data
      # Weekly breakdown for last 8 weeks
      @weekly_data = []
      8.times do |i|
        week_start = (i * 7).days.ago.beginning_of_week
        week_end = week_start.end_of_week

        reports = FraudReport
          .where(created_at: week_start..week_end)
          .where("reason LIKE ?", "LOW_QUALITY:%")
          .count

        resolutions = FraudReport
          .where(updated_at: week_start..week_end)
          .where("reason LIKE ?", "LOW_QUALITY:%")
          .resolved
          .count

        @weekly_data.unshift({
          week: "#{week_start.strftime('%m/%d')} - #{week_end.strftime('%m/%d')}",
          reports: reports,
          resolutions: resolutions
        })
      end
    end

    def calculate_percentage_change(old_value, new_value)
      return 0 if old_value == 0 && new_value == 0
      return 100 if old_value == 0 && new_value > 0
      return -100 if old_value > 0 && new_value == 0

      ((new_value - old_value).to_f / old_value * 100).round(1)
    end

    def authenticate_ship_certifier!
      redirect_to root_path unless current_user&.admin_or_ship_certifier?
    end
  end
end
