class AddSiteActionToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :site_action, :integer
  end
end
