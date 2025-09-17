class AddExcludedFromPoolToShipEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_events, :excluded_from_pool, :boolean, null: false, default: false
  end
end
