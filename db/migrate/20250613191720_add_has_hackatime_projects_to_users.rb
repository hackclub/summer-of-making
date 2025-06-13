class AddHasHackatimeProjectsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :has_hackatime_projects, :boolean, default: false, null: false
  end
end
