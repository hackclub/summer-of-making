class AddMagicReporterForeignKey < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_foreign_key :projects, :users, column: :magic_reporter_id, on_delete: :nullify, validate: false
    validate_foreign_key :projects, :users
  end
end
