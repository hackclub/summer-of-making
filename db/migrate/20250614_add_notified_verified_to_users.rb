class AddNotifiedVerifiedToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :notified_verified, :boolean, default: false
  end
end
