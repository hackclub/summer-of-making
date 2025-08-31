class CreateSinkeningSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :sinkening_settings do |t|
      t.float :strength, default: 1.0

      t.timestamps
    end

    # Create the initial record
    reversible do |dir|
      dir.up do
        execute "INSERT INTO sinkening_settings (strength, created_at, updated_at) VALUES (1.0, NOW(), NOW())"
      end
    end
  end
end
