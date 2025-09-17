class AddResolutionFieldsDetailsToFraudReports < ActiveRecord::Migration[8.0]
  def change
    add_column :fraud_reports, :resolved_outcome, :string
    add_column :fraud_reports, :resolved_message, :text
  end
end
