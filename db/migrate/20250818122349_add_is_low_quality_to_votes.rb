class AddIsLowQualityToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :is_low_quality, :boolean, default: false, null: false
  end
end
