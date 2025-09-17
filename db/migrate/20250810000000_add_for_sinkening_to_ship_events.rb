class AddForSinkeningToShipEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_events, :for_sinkening, :boolean, default: false,
                                                       null: false,
                                                       if_not_exists: true
  end
end
