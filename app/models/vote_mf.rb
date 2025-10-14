# == Schema Information
#
# Table name: vote_mfs
#
#  id                   :bigint           not null, primary key
#  ballot               :jsonb            not null
#  time_spent_voting_ms :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  project_id           :bigint           not null
#  voter_id             :bigint           not null
#
# Indexes
#
#  index_vote_mfs_on_project_id  (project_id)
#  index_vote_mfs_on_voter_id    (voter_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (voter_id => users.id)
#
class VoteMf < ApplicationRecord
    belongs_to :project
    belongs_to :voter, class_name: "User"

    CRITERIA = %w[technical creativity storytelling originality].freeze

    # 6-point scale, because 5-point scale leads to pepople picking the nice middle. "In 2006 the majority judgment experiment used five grades (see table 21.1b).
    # This was not the optimal choice; too often, judges waffled by giving the middle
    # grade, Good."

    GRADE_LABELS = [
        "Poor",         # 0
        "Mediocre",     # 1
        "Fair",         # 2
        "Good",         # 3
        "Very good",    # 4
        "Excellent"     # 5
    ].freeze

    GRADE_LABEL_TO_INT = GRADE_LABELS.each_with_index.to_h.transform_keys { |k| k.downcase }

    before_validation :normalize_ballot!

    validates :time_spent_voting_ms, numericality: { greater_than: 0 }
    validates :voter_id, uniqueness: { scope: :project_id }
    validate :validate_ballot

  # it will return a 0.0..1.0 (b/w 0 and 1) normalized composite score across all criteria – sum / n_critieria * (label - 1)
  def normalized_total_score
    values = ballot.is_a?(Hash) ? ballot.values : []
    return nil if values.empty?

    int_values = values.map(&:to_i)
    max_total = (CRITERIA.size * (GRADE_LABELS.size - 1)).to_f
    return 0.0 if max_total <= 0

    (int_values.sum / max_total).clamp(0.0, 1.0)
  end

    def ballot_labels
        return {} unless ballot.is_a?(Hash)
        ballot.to_h.transform_values do |v|
            int = v.is_a?(String) ? GRADE_LABEL_TO_INT[v.downcase] : v
            GRADE_LABELS[int.to_i] if int.is_a?(Integer) && int.between?(0, 5)
        end.compact
    end

    private

    def normalize_ballot!
        b = ballot.dup
        normalized = {}
        CRITERIA.each do |criterion|
            raw = b[criterion]
            next if raw.nil?
            value = GRADE_LABEL_TO_INT[raw.strip.downcase]
            normalized[criterion] = value unless value.nil?
        end
        self.ballot = normalized
    end

    def validate_ballot
        errors.add(:ballot, "must be a JSON object") and return unless ballot.is_a?(Hash)

        missing = CRITERIA - ballot.keys.map(&:to_s)
        errors.add(:ballot, "is missing required criteria: #{missing.join(', ')}") unless missing.empty?

        ballot.each do |criterion, value|
            unless CRITERIA.include?(criterion.to_s)
                errors.add(:ballot, "contains unknown criterion '#{criterion}'")
                next
            end
        end
    end
end
