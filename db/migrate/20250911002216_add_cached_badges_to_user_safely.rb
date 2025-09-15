class AddCachedBadgesToUserSafely < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :badges, :string, array: true unless column_exists?(:users, :badges)

    change_column_default :users, :badges, []

    safety_assured do
      User.in_batches(of: 10_000).update_all(badges: [])
    end
  end

  def down
    remove_column :users, :badges if column_exists?(:users, :badges)
  end
end
