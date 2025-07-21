class AddPreauthInstructionsColumnToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :hcb_preauthorization_instructions, :text
  end
end
