# frozen_string_literal: true

class FraudReportsController < ApplicationController
  before_action :authenticate_user!

  def create
    fraud_report = FraudReport.new(
      reporter: current_user,
      **fraud_report_params
    )

    # must be in the current voting pair
    if fraud_report.suspect_type == "ShipEvent"
      current_ids = current_user.user_vote_queue&.current_ship_events&.map(&:id) || []
      unless current_ids.include?(fraud_report.suspect_id)
        flash[:alert] = "Invalid report target."
        redirect_to request.referer || root_path
        return
      end
    end

    unless valid_report(fraud_report)
      flash[:alert] = "nice try silly!"
      redirect_to request.referer || root_path
      return
    end

    if fraud_report.save
      advanced = false
      # so we have kinds of report to triage and suspect_type where it's either Project or ShipEvent. ShipEvent is the suspect in voting page. Project is elsewhere.
      kind = params[:report_kind]
      case kind
      when "ai_undeclared"
        fraud_report.update_column(:reason, "AI_UNDECLARED: #{fraud_report.reason.to_s.strip}")
      when "low_quality"
        fraud_report.update_column(:reason, "LOW_QUALITY: #{fraud_report.reason.to_s.strip}")
      else # other
        fraud_report.update_column(:reason, "OTHER: #{fraud_report.reason.to_s.strip}")
      end

      # only dm the first time and auto-exclude after 3 low-quality reports
      if fraud_report.reason.to_s.start_with?("LOW_QUALITY:")
        c = FraudReport.unresolved.where(suspect_type: fraud_report.suspect_type, suspect_id: fraud_report.suspect_id).count
        if c == 1
          owner = if fraud_report.suspect_type == "ShipEvent"
            ShipEvent.find_by(id: fraud_report.suspect_id)&.user
          else
            Project.find_by(id: fraud_report.suspect_id)&.user
          end
          if owner&.slack_id.present?
            thing = fraud_report.suspect_type == "ShipEvent" ? "ship" : "project"
            msg = <<~EOT
            Heads up — someone reported your #{thing} as low-effort.
            Thanks for building! Our shipwrights will review and follow up if needed. No action is required right now.
            EOT
            SendSlackDmJob.perform_later(owner.slack_id, msg)
          end
        end
        if c >= 3 && fraud_report.suspect_type == "ShipEvent"
          ShipEvent.where(id: fraud_report.suspect_id).update_all(excluded_from_pool: true)
          msg = <<~EOT
          Heads up — your ship has been excluded from voting due to multiple low-quality reports.
          Thanks for building! Our shipwrights will review and follow up if needed. No action is required right now.
          EOT
          SendSlackDmJob.perform_later(owner.slack_id, msg)
        end
      end

      # advance the vote queue if this report was filed from the voting page
      if fraud_report.suspect_type == "ShipEvent"
        if current_user.user_vote_queue&.current_ship_events&.map(&:id)&.include?(fraud_report.suspect_id)
          current_user.advance_vote_queue!
          advanced = true
        end
      end

      base_msg = "Thank you – your report has been received and will be reviewed promptly."
      flash[:notice] = advanced ? "#{base_msg} We’ve moved you to the next matchup." : base_msg
      redirect_to request.referer || root_path
    else
      if fraud_report.errors[:user_id].any?
        flash[:notice] = "Thanks – you already filed a report for this. We won’t duplicate it."
      else
        flash[:alert] = "We couldn’t submit your report. Please try again."
      end
      redirect_to request.referer || root_path
    end
  rescue => e
    Rails.logger.error "Fraud report creation failed: #{e.message}"
    Honeybadger.notify(e)
    flash[:alert] = "Unable to submit report. Please try again."
    redirect_to request.referer || root_path
  end

  private

  def fraud_report_params
    raw = params.require(:fraud_report).permit(:subject_type, :subject_id, :suspect_type, :suspect_id, :reason)
    type = raw[:subject_type].presence || raw[:suspect_type]
    id = raw[:subject_id].presence || raw[:suspect_id]
    { suspect_type: type, suspect_id: id, reason: raw[:reason] }
  end


  def valid_report(fraud_report)
    reason = fraud_report.reason.to_s
    kind = params[:report_kind]

    return false if reason.blank? || reason.length < 20
    return false if reason.length > 1000
    sr = ActionController::Base.helpers.strip_tags(reason)
    fraud_report.reason = sr.strip

    sussy = [
      /<script/i,
      /javascript:/i,
      /on\w+\s*=/i,
      /<iframe/i,
      /<object/i,
      /<embed/i,
      /<form/i,
      /data:text\/html/i,
      /vbscript:/i,
      /<meta/i
    ]

    sussy.each do |pattern|
      return false if reason.match?(pattern)
    end

    sc = reason.scan(/[<>{}()\[\]"'`]/).length
    return false if sc > 10

    ac = reason.scan(/[a-zA-Z0-9\s]/).length
    return false if ac < (reason.length * 0.7)

    true
  end
end
