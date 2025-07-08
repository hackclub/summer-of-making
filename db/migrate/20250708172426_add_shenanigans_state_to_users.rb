class AddShenanigansStateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :shenanigans_state, :jsonb, default: {}
  end
end
