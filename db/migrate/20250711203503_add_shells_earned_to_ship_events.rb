class AddShellsEarnedToShipEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_events, :shells_earned, :integer, default: 0, null: false
  end
end
