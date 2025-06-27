# frozen_string_literal: true

# == Schema Information
#
# Table name: votes
#
#  id                   :bigint           not null, primary key
#  explanation          :text             not null
#  loser_demo_opened    :boolean          default(FALSE)
#  loser_readme_opened  :boolean          default(FALSE)
#  loser_repo_opened    :boolean          default(FALSE)
#  music_played         :boolean
#  time_spent_voting_ms :integer
#  winner_demo_opened   :boolean          default(FALSE)
#  winner_readme_opened :boolean          default(FALSE)
#  winner_repo_opened   :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  loser_id             :bigint
#  user_id              :bigint           not null
#  winner_id            :bigint           not null
#
# Indexes
#
#  index_votes_on_loser_id               (loser_id)
#  index_votes_on_user_id                (user_id)
#  index_votes_on_user_id_and_winner_id  (user_id,winner_id) UNIQUE
#  index_votes_on_winner_id              (winner_id)
#
# Foreign Keys
#
#  fk_rails_...  (loser_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (winner_id => projects.id)
#
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :winner, class_name: "Project"
  belongs_to :loser, class_name: "Project"

  validates :explanation, presence: true, length: { minimum: 10 }
  validates :user_id, uniqueness: { scope: :winner_id, message: "has already voted for this project" }

  after_create :potentially_pay_out_yayyyyy

  attr_accessor :token

  def authorized_with_token?(token_data)
    return false unless token_data

    token_data["user_id"] == user_id &&
      token_data["project_id"].to_s == winner_id.to_s &&
      Time.zone.parse(token_data["expires_at"]) > Time.current
  end

  private

  def potentially_pay_out_yayyyyy
    # if loser.votes.count == Payout::VOTE_COUNT_REQUIRED

    # end
  end

  def unlerp(start, stop, value)
    return 0.0 if start == stop
    (value - start) / (stop - start).to_f
  end
end
