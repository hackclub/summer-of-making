class AddVotesCountToShipEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_events, :votes_count, :integer, default: 0, null: false
  end
end
