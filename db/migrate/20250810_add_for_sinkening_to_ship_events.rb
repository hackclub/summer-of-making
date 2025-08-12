class AddForSinkeningToShipEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :ship_events, :for_sinkening, :boolean, default: false, null: false
  end
end
