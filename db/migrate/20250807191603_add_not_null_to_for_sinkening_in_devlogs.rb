class AddNotNullToForSinkeningInDevlogs < ActiveRecord::Migration[8.0]
  def change
    # First, update any existing NULL values to false
    execute "UPDATE devlogs SET for_sinkening = false WHERE for_sinkening IS NULL"

    # Then add the NOT NULL constraint
    change_column_null :devlogs, :for_sinkening, false
  end
end
