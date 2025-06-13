class CreateAirtableHighSeasBookStorySubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :airtable_high_seas_book_story_submissions do |t|
      t.string :airtable_id
      t.jsonb :airtable_fields

      t.timestamps
    end
  end
end
