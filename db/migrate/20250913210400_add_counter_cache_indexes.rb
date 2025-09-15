class AddCounterCacheIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Add indexes concurrently to avoid blocking table access
    add_index :projects, :ship_events_count, algorithm: :concurrently
    add_index :projects, :followers_count, algorithm: :concurrently
    add_index :users, :projects_count, algorithm: :concurrently
    add_index :users, :votes_count, algorithm: :concurrently
    add_index :users, :ship_events_count, algorithm: :concurrently
  end
end
