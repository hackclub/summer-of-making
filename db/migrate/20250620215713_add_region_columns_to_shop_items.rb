class AddRegionColumnsToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :enabled_us, :boolean, default: false
    add_column :shop_items, :enabled_eu, :boolean, default: false
    add_column :shop_items, :enabled_in, :boolean, default: false
    add_column :shop_items, :enabled_ca, :boolean, default: false
    add_column :shop_items, :enabled_au, :boolean, default: false
    add_column :shop_items, :enabled_xx, :boolean, default: false
    add_column :shop_items, :price_offset_us, :decimal, precision: 6, scale: 2, default: 0.0
    add_column :shop_items, :price_offset_eu, :decimal, precision: 6, scale: 2, default: 0.0
    add_column :shop_items, :price_offset_in, :decimal, precision: 6, scale: 2, default: 0.0
    add_column :shop_items, :price_offset_ca, :decimal, precision: 6, scale: 2, default: 0.0
    add_column :shop_items, :price_offset_au, :decimal, precision: 6, scale: 2, default: 0.0
    add_column :shop_items, :price_offset_xx, :decimal, precision: 6, scale: 2, default: 0.0
  end
end
