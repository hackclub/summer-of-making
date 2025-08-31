class AddWarehousePackageToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :shop_orders, :warehouse_package, null: true, foreign_key: { to_table: :shop_warehouse_packages }
  end
end
