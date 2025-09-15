class AddCounterCacheToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Add columns without defaults to avoid table locks
    safety_assured do
      execute "SET lock_timeout = '60s'"
    end
    add_column :users, :projects_count, :integer
    add_column :users, :devlogs_count, :integer
    add_column :users, :votes_count, :integer
    add_column :users, :ship_events_count, :integer
    safety_assured do
      execute "SET lock_timeout = '3s'"
    end
  end
end
