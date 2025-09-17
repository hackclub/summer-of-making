class CreateProjectImprovements < ActiveRecord::Migration[8.0]
  def change
    create_table :project_improvements do |t|
      t.references :project, null: false, foreign_key: true
      t.references :ship_certification, null: false, foreign_key: true
      t.text :description
      t.string :proof_link
      t.integer :status, default: 0
      t.integer :shell_reward, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    add_index :project_improvements, [ :project_id, :status ]
  end
end
