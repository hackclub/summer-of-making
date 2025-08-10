module Admin
  class FraudReportsController < ApplicationController
    before_action :authenticate_fraud_team!
    before_action :set_fraud_report, only: [ :show, :resolve, :unresolve ]

    def index
      @total_reports = FraudReport.count
      @resolved_reports = FraudReport.resolved.count
      @unresolved_reports = FraudReport.unresolved.count
      @unique_projects = FraudReport.where(suspect_type: "Project").select(:suspect_id).distinct.count
      @recent_reports = FraudReport.where("created_at >= ?", 24.hours.ago).count
      @fraud_reports = FraudReport.order(created_at: :desc).includes(:reporter, :suspect).limit(100)
    end

    def show
      # @fraud_report is set by before_action
    end

    def resolve
      @fraud_report.resolve!
      redirect_to admin_fraud_report_path(@fraud_report), notice: "Fraud report marked as resolved."
    end

    def unresolve
      @fraud_report.unresolve!
      redirect_to admin_fraud_report_path(@fraud_report), notice: "Fraud report marked as unresolved."
    end

    private

    def authenticate_fraud_team!
      redirect_to root_path unless current_user&.admin_or_fraud_team_member?
    end

    def set_fraud_report
      @fraud_report = FraudReport.find(params[:id])
    end
  end
end
