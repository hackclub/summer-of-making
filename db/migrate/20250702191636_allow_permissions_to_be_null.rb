class AllowPermissionsToBeNull < ActiveRecord::Migration[8.0]
  def up
    change_column_null :users, :permissions, true
  end

  def down
    # Update any null permissions to empty array before adding not null constraint back
    execute "UPDATE users SET permissions = '[]' WHERE permissions IS NULL"
    change_column_null :users, :permissions, false
  end
end
