class AddDefaultToForSinkeningInDevlogs < ActiveRecord::Migration[8.0]
  def change
    change_column_default :devlogs, :for_sinkening, false
  end
end
