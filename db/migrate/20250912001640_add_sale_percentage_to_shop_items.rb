class AddSalePercentageToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :sale_percentage, :integer
  end
end
