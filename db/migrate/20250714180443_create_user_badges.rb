class CreateUserBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.string :badge_key, null: false
      t.datetime :earned_at, null: false

      t.timestamps
    end

    add_index :user_badges, [ :user_id, :badge_key ], unique: true
    add_index :user_badges, :badge_key
  end
end
