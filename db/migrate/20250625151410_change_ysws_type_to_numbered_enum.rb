class ChangeYswsTypeToNumberedEnum < ActiveRecord::Migration[8.0]
  def up
    # Add a new temporary column to store the converted values
    add_column :projects, :ysws_type_temp, :integer

    # Convert string values to integer values
    execute <<-SQL
      UPDATE projects SET ysws_type_temp = CASE#{' '}
        WHEN ysws_type = 'Athena' THEN 1
        WHEN ysws_type = 'Boba Drops' THEN 2
        WHEN ysws_type = 'Cider' THEN 3
        WHEN ysws_type = 'Grub' THEN 4
        WHEN ysws_type = 'Hackaccino' THEN 5
        WHEN ysws_type = 'Highway' THEN 6
        WHEN ysws_type = 'Neighborhood' THEN 7
        WHEN ysws_type = 'Shipwrecked' THEN 8
        WHEN ysws_type = 'Solder' THEN 9
        WHEN ysws_type = 'Sprig' THEN 10
        WHEN ysws_type = 'Swirl' THEN 11
        WHEN ysws_type = 'Terminalcraft' THEN 12
        WHEN ysws_type = 'Thunder' THEN 13
        WHEN ysws_type = 'Tonic' THEN 14
        WHEN ysws_type = 'Toppings' THEN 15
        WHEN ysws_type = 'Waffles' THEN 16
        WHEN ysws_type = 'Waveband' THEN 17
        WHEN ysws_type = 'FIX IT!' THEN 18
        WHEN ysws_type = 'Other' THEN 0
        ELSE 0
      END
    SQL

    # Remove the old column and rename the new one
    remove_column :projects, :ysws_type
    rename_column :projects, :ysws_type_temp, :ysws_type
  end

  def down
    # Add a temporary column to store the converted values
    add_column :projects, :ysws_type_temp, :string

    # Convert integer values back to string values
    execute <<-SQL
      UPDATE projects SET ysws_type_temp = CASE#{' '}
        WHEN ysws_type = 1 THEN 'Athena'
        WHEN ysws_type = 2 THEN 'Boba Drops'
        WHEN ysws_type = 3 THEN 'Cider'
        WHEN ysws_type = 4 THEN 'Grub'
        WHEN ysws_type = 5 THEN 'Hackaccino'
        WHEN ysws_type = 6 THEN 'Highway'
        WHEN ysws_type = 7 THEN 'Neighborhood'
        WHEN ysws_type = 8 THEN 'Shipwrecked'
        WHEN ysws_type = 9 THEN 'Solder'
        WHEN ysws_type = 10 THEN 'Sprig'
        WHEN ysws_type = 11 THEN 'Swirl'
        WHEN ysws_type = 12 THEN 'Terminalcraft'
        WHEN ysws_type = 13 THEN 'Thunder'
        WHEN ysws_type = 14 THEN 'Tonic'
        WHEN ysws_type = 15 THEN 'Toppings'
        WHEN ysws_type = 16 THEN 'Waffles'
        WHEN ysws_type = 17 THEN 'Waveband'
        WHEN ysws_type = 18 THEN 'FIX IT!'
        WHEN ysws_type = 0 THEN 'Other'
        ELSE 'Other'
      END
    SQL

    # Remove the old column and rename the new one
    remove_column :projects, :ysws_type
    rename_column :projects, :ysws_type_temp, :ysws_type
  end
end
