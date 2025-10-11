class AddWrappedShareTokenIndexToUsers < ActiveRecord::Migration[8.0]
  def change
    add_index :users, :wrapped_share_token, unique: true, algorithm: :concurrently
  end
end
