class AddWrappedShareTokenToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :wrapped_share_token, :string
    add_index :users, :wrapped_share_token, unique: true, algorithm: :concurrently
  end
end
