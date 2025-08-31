class CreateShopWarehousePackages < ActiveRecord::Migration[8.0]
  def change
    create_table :shop_warehouse_packages do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :frozen_address, null: false
      t.string :theseus_package_id
      t.timestamps
    end

    add_index :shop_warehouse_packages, :theseus_package_id, unique: true
  end
end
