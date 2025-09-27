class AddUserAgentAndIpToVotes < ActiveRecord::Migration[8.0]
  def change
    add_column :votes, :user_agent, :string, null: true
    add_column :votes, :ip, :string, null: true
  end
end
