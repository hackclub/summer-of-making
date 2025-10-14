class CreateVoteMf < ActiveRecord::Migration[8.0]
  def change
    create_table :vote_mfs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :voter, null: false, foreign_key: true
      t.integer :time_spent_voting_ms

      t.timestamps
    end
  end
end
