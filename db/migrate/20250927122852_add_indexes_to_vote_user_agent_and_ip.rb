class AddIndexesToVoteUserAgentAndIp < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :votes, :user_agent, algorithm: :concurrently
    add_index :votes, :ip, algorithm: :concurrently
  end
end
