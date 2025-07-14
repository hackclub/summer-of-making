class CreateUserProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_profiles do |t|
      t.text :bio
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
