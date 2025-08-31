class RenameStrengthToIntensityInSinkeningSettings < ActiveRecord::Migration[8.0]
  def change
    # Check if the strength column exists before trying to rename it
    if column_exists?(:sinkening_settings, :strength)
      rename_column :sinkening_settings, :strength, :intensity
    end
  end
end
