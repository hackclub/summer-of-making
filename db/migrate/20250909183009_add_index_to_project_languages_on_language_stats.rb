class AddIndexToProjectLanguagesOnLanguageStats < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :project_languages, :language_stats, using: :gin, algorithm: :concurrently, if_not_exists: true
  end
end
