class AddUniqueIndexToProjectLanguagesProjectId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :project_languages, :project_id, unique: true, algorithm: :concurrently, name: 'index_project_languages_on_project_id_unique'

    remove_index :project_languages, name: 'index_project_languages_on_project_id', if_exists: true
  end

  def down
    add_index :project_languages, :project_id, algorithm: :concurrently, if_not_exists: true

    remove_index :project_languages, name: 'index_project_languages_on_project_id_unique', if_exists: true
  end
end
