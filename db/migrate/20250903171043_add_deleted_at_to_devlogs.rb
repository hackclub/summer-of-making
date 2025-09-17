class AddDeletedAtToDevlogs < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:devlogs, :deleted_at)
      add_column :devlogs, :deleted_at, :datetime
      add_index :devlogs, :deleted_at
    end
  end
end
