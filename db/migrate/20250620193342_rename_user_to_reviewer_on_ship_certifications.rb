class RenameUserToReviewerOnShipCertifications < ActiveRecord::Migration[8.0]
  def change
    rename_column :ship_certifications, :user_id, :reviewer_id
  end
end
