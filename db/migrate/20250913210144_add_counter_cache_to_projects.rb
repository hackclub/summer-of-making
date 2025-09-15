class AddCounterCacheToProjects < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    safety_assured do
      execute "SET lock_timeout = '60s'"
    end
    # Add columns without defaults to avoid table locks
    add_column :projects, :ship_events_count, :integer
    add_column :projects, :followers_count, :integer
    safety_assured do
      execute "SET lock_timeout = '3s'"
    end
  end
end
