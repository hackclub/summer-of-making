class AddMagicReporterToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :magic_reporter_id, :bigint
  end
end
