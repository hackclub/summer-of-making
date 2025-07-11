class AddHoursAtPayoutToShipEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_events, :hours_at_payout, :decimal, precision: 10, scale: 4, default: 0.0, null: false
  end
end
