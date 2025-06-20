class AddFreezeShopActivityToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :freeze_shop_activity, :boolean, default: false
  end
end
