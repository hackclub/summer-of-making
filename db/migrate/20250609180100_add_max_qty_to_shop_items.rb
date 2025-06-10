class AddMaxQtyToShopItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_items, :max_qty, :integer, default: 10
  end
end
