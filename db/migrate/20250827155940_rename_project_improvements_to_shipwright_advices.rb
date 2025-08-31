class RenameProjectImprovementsToShipwrightAdvices < ActiveRecord::Migration[8.0]
  def change
    rename_table :project_improvements, :shipwright_advices
  end
end
