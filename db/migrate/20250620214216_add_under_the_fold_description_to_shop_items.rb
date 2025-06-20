class AddUnderTheFoldDescriptionToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :under_the_fold_description, :text
  end
end
