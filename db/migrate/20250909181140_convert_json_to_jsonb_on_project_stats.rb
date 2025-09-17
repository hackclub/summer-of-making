class ConvertJsonToJsonbOnProjectStats < ActiveRecord::Migration[8.0]
  def up
    ProjectLanguage.update_all('new_language_stats_jsonb = language_stats::jsonb')
  end

  def down
    ProjectLanguage.update_all('language_stats = new_language_stats_jsonb::json')
  end
end
