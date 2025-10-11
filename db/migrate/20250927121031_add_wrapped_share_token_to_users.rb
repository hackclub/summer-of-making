class AddWrappedShareTokenColumnToUsers < ActiveRecord::Migration[8.0]
  def up
    old_timeout = select_value("SHOW lock_timeout")
    execute "SET lock_timeout = '20s';"
    add_column :users, :wrapped_share_token, :string
    execute "SET lock_timeout = '#{old_timeout}';"
  end

  def down
    remove_column :users, :wrapped_share_token
  end
end
