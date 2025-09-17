class AddNewTutorialProgressToTutorialProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorial_progresses, :new_tutorial_progress, :jsonb, null: false, default: {}
  end
end
