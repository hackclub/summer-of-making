class AddIsSinkeningShipToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :is_sinkening_ship, :boolean, default: false
  end
end
