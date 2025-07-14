class AddCustomCssToUserProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_profiles, :custom_css, :text
  end
end
