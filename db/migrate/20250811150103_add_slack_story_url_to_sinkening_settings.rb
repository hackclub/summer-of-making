class AddSlackStoryUrlToSinkeningSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :sinkening_settings, :slack_story_url, :string
  end
end
