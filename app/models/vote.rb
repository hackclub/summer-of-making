# frozen_string_literal: true

# == Schema Information
#
# Table name: votes
#
#  id                      :bigint           not null, primary key
#  explanation             :text             not null
#  invalid_reason          :text
#  marked_invalid_at       :datetime
#  music_played            :boolean
#  project_1_demo_opened   :boolean          default(FALSE)
#  project_1_readme_opened :boolean          default(FALSE)
#  project_1_repo_opened   :boolean          default(FALSE)
#  project_2_demo_opened   :boolean          default(FALSE)
#  project_2_readme_opened :boolean          default(FALSE)
#  project_2_repo_opened   :boolean          default(FALSE)
#  status                  :string           default("active"), not null
#  time_spent_voting_ms    :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  marked_invalid_by_id    :bigint
#  project_1_id            :bigint
#  project_2_id            :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_votes_on_marked_invalid_at     (marked_invalid_at)
#  index_votes_on_marked_invalid_by_id  (marked_invalid_by_id)
#  index_votes_on_project_1_id          (project_1_id)
#  index_votes_on_project_2_id          (project_2_id)
#  index_votes_on_status                (status)
#  index_votes_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (marked_invalid_by_id => users.id)
#  fk_rails_...  (project_1_id => projects.id)
#  fk_rails_...  (project_2_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :project_1, class_name: "Project", optional: true
  belongs_to :project_2, class_name: "Project", optional: true
  belongs_to :marked_invalid_by, class_name: "User", optional: true

  has_many :vote_changes, dependent: :destroy

  validates :explanation, presence: true, length: { minimum: 10 }
  validates :status, inclusion: { in: %w[active invalid] }

  attr_accessor :winning_project_id

  scope :active, -> { where(status: "active") }
  scope :invalid, -> { where(status: "invalid") }
  scope :recent, -> { order(created_at: :desc) }

  after_create :process_vote_results

  # Helper methods to get winner/loser/tied projects
  def winner_project
    winner_change = vote_changes.find_by(result: "win")
    winner_change&.project
  end

  def loser_project
    loser_change = vote_changes.find_by(result: "loss")
    loser_change&.project
  end

  def tied_project_ids
    vote_changes.where(result: "tie").pluck(:project_id)
  end

  def tied_projects
    Project.where(id: tied_project_ids)
  end

  def is_tie?
    vote_changes.where(result: "tie").exists?
  end

  def has_winner?
    vote_changes.where(result: "win").exists?
  end

  def projects
    vote_changes.includes(:project).map(&:project)
  end

  def authorized_with_token?(token_data)
    return false unless token_data

    return false unless token_data["user_id"].to_i == user_id.to_i
    return false unless token_data["project_1_id"].to_i == project_1_id.to_i
    return false unless token_data["project_2_id"].to_i == project_2_id.to_i
    return false unless Time.zone.parse(token_data["expires_at"]) > Time.current

    # check if the winning project is one of the two projects
    if winning_project_id.present?
      valid_project_ids = [ project_1_id.to_i, project_2_id.to_i ]
      return false unless valid_project_ids.include?(winning_project_id.to_i)
    end

    true
  end

  private

  def mark_invalid!(reason, marked_by_user)
    update!(
      status: "invalid",
      invalid_reason: reason,
      marked_invalid_at: Time.current,
      marked_invalid_by: marked_by_user
    )
  end

  def process_vote_results
    VoteProcessingService.new(self).process

    winner = vote_changes.where(result: "win").first
    loser = vote_changes.where(result: "loss").first

    # if winner.
  end
end
