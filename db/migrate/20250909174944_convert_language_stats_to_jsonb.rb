class ConvertLanguageStatsToJsonb < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    # Step 1: Add new jsonb column (check if it already exists)
    unless column_exists?(:project_languages, :language_stats_new)
      add_column :project_languages, :language_stats_new, :jsonb
    end

    # Step 2: Backfill data (only if original column still exists)
    if column_exists?(:project_languages, :language_stats)
      ProjectLanguage.find_each do |record|
        record.update_column(:language_stats_new, record.language_stats)
      end
      
      # Step 3: Remove old column and rename new one
      safety_assured { remove_column :project_languages, :language_stats }
    end
    
    # Rename the new column to the original name if needed
    if column_exists?(:project_languages, :language_stats_new)
      safety_assured { rename_column :project_languages, :language_stats_new, :language_stats }
    end

    # Step 4: Add not null constraint
    safety_assured { change_column_null :project_languages, :language_stats, false }
  end

  def down
    # Reverse the process
    add_column :project_languages, :language_stats_old, :json

    ProjectLanguage.find_each do |record|
      record.update_column(:language_stats_old, record.language_stats)
    end

    safety_assured { remove_column :project_languages, :language_stats }
    rename_column :project_languages, :language_stats_old, :language_stats
    change_column_null :project_languages, :language_stats, false
  end
end
