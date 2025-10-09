class AddIndexesToVoteTimeTrackingFields < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :votes, :time_on_tab_ms, algorithm: :concurrently
    add_index :votes, :time_off_tab_ms, algorithm: :concurrently
  end
end
