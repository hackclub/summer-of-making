class AddMagicLetterIdToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :magic_letter_id, :string
  end
end
