class AddOnePerPersonEverToShopItems < ActiveRecord::Migration[7.1]
  def change
    add_column :shop_items, :one_per_person_ever, :boolean, default: false
  end
end
