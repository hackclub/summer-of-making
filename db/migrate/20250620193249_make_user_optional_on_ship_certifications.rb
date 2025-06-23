class MakeUserOptionalOnShipCertifications < ActiveRecord::Migration[8.0]
  def change
    change_column_null :ship_certifications, :user_id, true
  end
end
