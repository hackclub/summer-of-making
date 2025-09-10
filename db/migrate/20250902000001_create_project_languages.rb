class CreateProjectLanguages < ActiveRecord::Migration[7.1]
  def change
    create_table :project_languages do |t|
      t.references :project, null: false, foreign_key: true
      t.json :language_stats, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :project_languages, :status
    add_index :project_languages, :last_synced_at
  end
end
