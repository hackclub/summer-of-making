class AddEscrowedToPayouts < ActiveRecord::Migration[8.0]
  def change
    add_column :payouts, :escrowed, :boolean, default: false, null: false
    add_index :payouts, :escrowed
  end
end
