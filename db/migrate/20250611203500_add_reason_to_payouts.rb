class AddReasonToPayouts < ActiveRecord::Migration[8.0]
  def change
    add_column :payouts, :reason, :string
  end
end
