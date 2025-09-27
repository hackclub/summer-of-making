class AddTimeTrackingToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :time_on_tab_ms, :integer
    add_column :votes, :time_off_tab_ms, :integer
  end
end
