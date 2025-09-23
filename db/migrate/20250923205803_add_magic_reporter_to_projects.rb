class AddMagicReporterToProjects < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_reference :projects, :magic_reporter, null: true, index: { algorithm: :concurrently }
  end
end
