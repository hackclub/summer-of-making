class EnsureAllUsersHavePermissionsArray < ActiveRecord::Migration[8.0]
  def up
    # First, update any users with null permissions
    execute "UPDATE users SET permissions = '[]' WHERE permissions IS NULL"

    # Then, ensure the column has the correct default and not null constraint
    change_column_default :users, :permissions, "[]"
    change_column_null :users, :permissions, false, "[]"
  end

  def down
    # No need to reverse this - we want to keep permissions as not null
  end
end
