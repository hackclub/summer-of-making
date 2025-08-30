class AddYswsFeedbackToShipCertifications < ActiveRecord::Migration[8.0]
  def change
    add_column :ship_certifications, :ysws_feedback_reasons, :text
    add_reference :ship_certifications, :ysws_returned_by, null: true, foreign_key: { to_table: :users }
    add_column :ship_certifications, :ysws_returned_at, :datetime
  end
end
