class AddUserToYswsReviewSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :ysws_review_submissions, :reviewer, null: true, foreign_key: { to_table: :users }
  end
end
