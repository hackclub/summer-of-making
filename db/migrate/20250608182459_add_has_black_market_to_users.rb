class AddHasBlackMarketToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :has_black_market, :boolean
  end
end
