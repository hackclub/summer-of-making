class SwapJsonForJsonbOnProjectStats < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      # This is an admin-only model that is written by background jobs, we're ok
      # with some errors on the frontend from mis-set column cache
      rename_column :project_languages, :language_stats, :old_language_stats
      rename_column :project_languages, :new_language_stats_jsonb, :language_stats
      ProjectLanguage.reset_column_information
    end
  end
end
