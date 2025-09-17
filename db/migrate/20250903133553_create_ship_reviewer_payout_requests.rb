class CreateShipReviewerPayoutRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :ship_reviewer_payout_requests do |t|
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.decimal :amount
      t.integer :status
      t.datetime :requested_at
      t.datetime :approved_at
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.integer :decisions_count

      t.timestamps
    end
  end
end
