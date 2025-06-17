class AddLimitedStockToShopItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_items, :limited, :boolean, default: false
    add_column :shop_items, :stock, :integer
  end
end
