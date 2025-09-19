class AddRecertificationInstructionsToShipCertifications < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_certifications, :recertification_instructions, :text unless column_exists?(:ship_certifications, :recertification_instructions)
  end
end
