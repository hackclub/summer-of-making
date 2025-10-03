class AddIndexesToFraudReportsAndShipCertifications < ActiveRecord::Migration[8.0]
  # Disable DDL transaction to allow concurrent index creation
  # This prevents table locking on large tables in production
  disable_ddl_transaction!

  def change
    # Add index for resolved_at on fraud_reports for efficient filtering in analytics
    # CONCURRENT: Does not block reads/writes during index creation
    add_index :fraud_reports, :resolved_at, algorithm: :concurrently, if_not_exists: true

    # Add index for resolved_by_id on fraud_reports for efficient admin resolution tracking
    # CONCURRENT: Does not block reads/writes during index creation
    add_index :fraud_reports, :resolved_by_id, algorithm: :concurrently, if_not_exists: true

    # Add composite index for common query pattern: resolved fraud reports by date range
    # CONCURRENT: Does not block reads/writes during index creation
    add_index :fraud_reports, [ :resolved, :resolved_at ], algorithm: :concurrently, if_not_exists: true

    # Add index for ysws_returned_at on ship_certifications for YSWS leaderboard queries
    # CONCURRENT: Does not block reads/writes during index creation
    add_index :ship_certifications, :ysws_returned_at, algorithm: :concurrently, if_not_exists: true

    # Add index for ysws_returned_by_id on ship_certifications for YSWS reviewer tracking
    # CONCURRENT: Does not block reads/writes during index creation
    add_index :ship_certifications, :ysws_returned_by_id, algorithm: :concurrently, if_not_exists: true
  end
end
