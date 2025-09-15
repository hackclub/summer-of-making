class BackfillCounterCaches < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET lock_timeout = '60s'"
    end

    # Set default values first, then NOT NULL constraints
    Project.unscoped.where(ship_events_count: nil).update_all(ship_events_count: 0)
    change_column_default :projects, :ship_events_count, 0
    Project.unscoped.where(followers_count: nil).update_all(followers_count: 0)
    change_column_default :projects, :followers_count, 0
    User.unscoped.where(projects_count: nil).update_all(projects_count: 0)
    change_column_default :users, :projects_count, 0
    User.unscoped.where(devlogs_count: nil).update_all(devlogs_count: 0)
    change_column_default :users, :devlogs_count, 0
    User.unscoped.where(votes_count: nil).update_all(votes_count: 0)
    change_column_default :users, :votes_count, 0
    User.unscoped.where(ship_events_count: nil).update_all(ship_events_count: 0)
    change_column_default :users, :ship_events_count, 0

    # Safe to add NOT NULL since we backfilled and set defaults
    safety_assured do
      change_column_null :projects, :ship_events_count, false
      change_column_null :projects, :followers_count, false
      change_column_null :users, :projects_count, false
      change_column_null :users, :devlogs_count, false
      change_column_null :users, :votes_count, false
      change_column_null :users, :ship_events_count, false
    end

    safety_assured do
      execute "SET lock_timeout = '3s'"
    end
  end

  def down
    safety_assured do
      execute "SET lock_timeout = '3s'"
    end
  end
end
