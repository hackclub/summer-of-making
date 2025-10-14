class AddBallotToVoteMf < ActiveRecord::Migration[8.0]
  def change
    add_column :vote_mfs, :ballot, :jsonb
  end
end
