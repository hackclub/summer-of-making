class AddResolutionFieldsToFraudReports < ActiveRecord::Migration[8.0]
  def change
    add_column :fraud_reports, :resolved_at, :datetime
    add_column :fraud_reports, :resolved_by_id, :bigint
    add_column :fraud_reports, :category, :string

    add_index :fraud_reports, :resolved_by_id
    add_index :fraud_reports, :category
    add_foreign_key :fraud_reports, :users, column: :resolved_by_id
  end
end
