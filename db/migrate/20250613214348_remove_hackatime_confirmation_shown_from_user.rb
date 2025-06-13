class RemoveHackatimeConfirmationShownFromUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :hackatime_confirmation_shown
  end
end
