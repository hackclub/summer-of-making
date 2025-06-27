class AddEnabledToShopItems < ActiveRecord::Migration[8.0]
  def up
    add_column :shop_items, :enabled, :boolean
    execute "update shop_items set enabled = TRUE;"
  end
  def down
    remove_column :shop_items, :enabled
  end
end
