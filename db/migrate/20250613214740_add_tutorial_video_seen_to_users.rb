class AddTutorialVideoSeenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tutorial_video_seen, :boolean, default: false, null: false
  end
end
