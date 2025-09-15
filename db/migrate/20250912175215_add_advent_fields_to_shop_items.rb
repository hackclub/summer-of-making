class AddAdventFieldsToShopItems < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  def change
    add_column :shop_items, :unlock_on, :date
    add_column :shop_items, :special, :boolean, default: false, null: false
    add_column :shop_items, :campfire_only, :boolean, default: true, null: false
    add_column :shop_items, :advent_announced, :boolean, default: false, null: false
    add_index :shop_items, :unlock_on, algorithm: :concurrently
  end
end
