class CreateUserVoteQueues < ActiveRecord::Migration[8.0]
  def change
    create_table :user_vote_queues do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :ship_event_pairs, null: false, default: []
      t.integer :current_position, null: false, default: 0
      t.datetime :last_generated_at

      t.timestamps
    end

    add_index :user_vote_queues, :user_id, unique: true, name: 'index_user_vote_queues_on_user_id_unique'
    add_index :user_vote_queues, :current_position
    add_index :user_vote_queues, :last_generated_at
  end
end
