class AddFraudTeamMemberToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :fraud_team_member, :boolean, default: false, null: false
  end
end
