class AddSlackIdToEmailSignups < ActiveRecord::Migration[7.1]
  def change
    add_column :email_signups, :slack_id, :string
  end
end
