class AddShopPerformanceIndices < ActiveRecord::Migration[8.0]
  def change
    # CRITICAL: ShopItems filtering indices (most important!)
    add_index :shop_items, [ :enabled, :requires_black_market, :ticket_cost ],
              name: "idx_shop_items_enabled_black_market_price"

    # Regional filtering performance
    add_index :shop_items, [ :enabled, :enabled_us, :enabled_eu, :enabled_in, :enabled_ca, :enabled_au, :enabled_xx ],
              name: "idx_shop_items_regional_enabled"

    # ShopItem type filtering (for FreeStickers query)
    add_index :shop_items, [ :type, :enabled ], name: "idx_shop_items_type_enabled"

    # CRITICAL: ShopOrders performance indices
    # For the heavy aggregation queries
    add_index :shop_orders, [ :shop_item_id, :aasm_state, :quantity ],
              name: "idx_shop_orders_item_state_qty"

    # For user-specific order lookups
    add_index :shop_orders, [ :user_id, :shop_item_id, :aasm_state ],
              name: "idx_shop_orders_user_item_state"

    # For one_per_person_ever checks
    add_index :shop_orders, [ :user_id, :shop_item_id ],
              name: "idx_shop_orders_user_item_unique"

    # ShopItems stock calculations (remaining_stock method)
    add_index :shop_orders, [ :shop_item_id, :aasm_state ],
              name: "idx_shop_orders_stock_calc"
  end
end
