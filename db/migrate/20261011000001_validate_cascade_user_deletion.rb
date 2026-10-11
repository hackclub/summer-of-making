require_relative "20261011000000_cascade_user_deletion"


class ValidateCascadeUserDeletion < ActiveRecord::Migration[8.0]
  def change
    (CascadeUserDeletion::CASCADE + CascadeUserDeletion::NULLIFY).each do |from, to, column|
      validate_foreign_key from, to, column: column
    end
  end
end
