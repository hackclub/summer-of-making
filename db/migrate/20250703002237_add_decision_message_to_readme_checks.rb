class AddDecisionMessageToReadmeChecks < ActiveRecord::Migration[8.0]
  def change
    add_column :readme_checks, :decision_message, :string
  end
end
