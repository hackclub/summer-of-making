class AddForSinkeningToShipEvents < ActiveRecord::Migration[6.0]
  def up
    add_column :ship_events, :for_sinkening, :boolean, default: false, null: false
  end
  def down
    # intentionally left blank
  end
end
