class AddProcessedAtAndAiFeedbackToVotes < ActiveRecord::Migration[7.0]
  def change
    add_column :votes, :processed_at, :datetime
    add_column :votes, :ai_feedback, :text
  end
end
