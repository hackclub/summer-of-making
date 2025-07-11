class PopulateCounterCaches < ActiveRecord::Migration[8.0]
  def up
    # Reset counter caches for votes_count on ship_events
    ShipEvent.find_each do |ship_event|
      votes_count = Vote.where("ship_event_1_id = ? OR ship_event_2_id = ?", ship_event.id, ship_event.id).count
      ship_event.update_column(:votes_count, votes_count)
    end

    # Reset counter caches for vote_changes_count on projects
    Project.find_each do |project|
      vote_changes_count = VoteChange.where(project_id: project.id).count
      project.update_column(:vote_changes_count, vote_changes_count)
    end
  end

  def down
    # Reset to zero if rolling back
    ShipEvent.update_all(votes_count: 0)
    Project.update_all(vote_changes_count: 0)
  end
end
