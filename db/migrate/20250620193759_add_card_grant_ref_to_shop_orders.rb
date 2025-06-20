class AddCardGrantRefToShopOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :shop_orders, :shop_card_grant, null: true, foreign_key: true
  end
end
