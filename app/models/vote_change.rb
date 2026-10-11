# frozen_string_literal: true

# == Schema Information
#
# Table name: vote_changes
#
#  id                 :bigint           not null, primary key
#  elo_after          :integer          not null
#  elo_before         :integer          not null
#  elo_delta          :integer          not null
#  project_vote_count :integer          not null
#  result             :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  project_id         :bigint           not null
#  vote_id            :bigint           not null
#
# Indexes
#
#  index_vote_changes_on_project_id                 (project_id)
#  index_vote_changes_on_project_id_and_created_at  (project_id,created_at)
#  index_vote_changes_on_result                     (result)
#  index_vote_changes_on_vote_id                    (vote_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id) ON DELETE => cascade
#  fk_rails_...  (vote_id => votes.id) ON DELETE => cascade
#
class VoteChange < ApplicationRecord
  belongs_to :vote
  belongs_to :project

  validates :elo_before, :elo_after, :elo_delta, presence: true
  validates :result, presence: true, inclusion: { in: %w[win loss tie] }
  validates :project_vote_count, presence: true, numericality: { greater_than: 0 }

  after_create :try_payout

  scope :wins, -> { where(result: "win") }
  scope :losses, -> { where(result: "loss") }
  scope :ties, -> { where(result: "tie") }

  def self.cumulative_elo_range_for_vote_count(vote_count, calculate_to = Time.now)
    vote_changes = where("project_vote_count <= ?", vote_count)
    vote_changes = vote_changes.where("created_at <= ?", calculate_to) if calculate_to

    return [ nil, nil ] if vote_changes.empty?

    [ vote_changes.minimum(:elo_after), vote_changes.maximum(:elo_after) ]
  end

  def elo_gained?
    elo_delta > 0
  end

  def elo_lost?
    elo_delta < 0
  end

  private

  def try_payout
    genesis_has_run = Payout.where(payable_type: "ShipEvent").any?
    project.issue_payouts if genesis_has_run && !project.is_deleted?
  end
end
