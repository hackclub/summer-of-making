class AddForSinkeningToDevlogs < ActiveRecord::Migration[8.0]
  def change
    add_column :devlogs, :for_sinkening, :boolean
  end
end
