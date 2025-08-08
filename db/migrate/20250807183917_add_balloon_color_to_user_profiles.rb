class AddBalloonColorToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :balloon_color, :string
  end
end
