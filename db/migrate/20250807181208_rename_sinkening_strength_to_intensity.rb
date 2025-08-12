class RenameSinkeningStrengthToIntensity < ActiveRecord::Migration[8.0]
  def change
    rename_column :sinkening_settings, :strength, :intensity
  end
end
