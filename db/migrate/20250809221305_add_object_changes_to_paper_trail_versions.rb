class AddObjectChangesToPaperTrailVersions < ActiveRecord::Migration[8.0]
  def change
    add_column :versions, :object_changes, :jsonb
  end
end
