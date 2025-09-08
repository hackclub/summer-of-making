class AddMagickedAtToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :magicked_at, :datetime
  end
end
