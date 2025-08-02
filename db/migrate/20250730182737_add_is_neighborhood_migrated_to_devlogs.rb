class AddIsNeighborhoodMigratedToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :is_neighborhood_migrated, :boolean, default: false, null: false
  end
end
