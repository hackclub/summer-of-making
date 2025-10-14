class AddWrappedShareTokenToUsers < ActiveRecord::Migration[8.0]
  def up
    old_timeout = select_value("SHOW lock_timeout")
    safety_assured { execute "SET lock_timeout = '5s';" }
    add_column :users, :wrapped_share_token, :string
    safety_assured { execute "SET lock_timeout = '#{old_timeout}';" }
  end

  def down
    remove_column :users, :wrapped_share_token
  end
end
