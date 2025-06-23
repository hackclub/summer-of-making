class CreateShipCertifications < ActiveRecord::Migration[8.0]
  def change
    create_table :ship_certifications do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :project, null: false, foreign_key: true
      t.integer :judgement, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :ship_certifications, [ :project_id, :judgement ]
  end
end
