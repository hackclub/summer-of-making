class AddCertificationTypeToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :certification_type, :integer
  end
end
