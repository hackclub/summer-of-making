class AddJsonbFieldToProjectStats < ActiveRecord::Migration[8.0]
  def change
    add_column :project_languages, :new_language_stats_jsonb, :jsonb, default: '{}'
  end
end
