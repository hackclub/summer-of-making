class AddVoteChangesCountToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :vote_changes_count, :integer, default: 0, null: false
  end
end
