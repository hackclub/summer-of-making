class CreateUserAdventStickers < ActiveRecord::Migration[8.0]
  def change
    create_table :user_advent_stickers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :shop_item, null: false, foreign_key: true
      t.references :devlog, null: false, foreign_key: true
      t.date :earned_on, null: false

      t.timestamps
    end
    add_index :user_advent_stickers, [ :user_id, :shop_item_id ], unique: true
    add_index :user_advent_stickers, :earned_on
  end
end
