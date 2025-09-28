# frozen_string_literal: true

require "set"

# == Schema Information
#
# Table name: user_vote_queues
#
#  id                :bigint           not null, primary key
#  current_position  :integer          default(0), not null
#  last_generated_at :datetime
#  ship_event_pairs  :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_user_vote_queues_on_current_position   (current_position)
#  index_user_vote_queues_on_last_generated_at  (last_generated_at)
#  index_user_vote_queues_on_user_id            (user_id)
#  index_user_vote_queues_on_user_id_unique     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserVoteQueue < ApplicationRecord
  belongs_to :user

  validates :current_position, presence: true, numericality: { greater_than_or_equal_to: 0 }

  QUEUE_SIZE = 15
  # do note that we trigger a refill job if we hit the refill threshold not when we have depelted the queue
  REFILL_THRESHOLD = 5

  TUTORIAL_PAIR = [ 2984, 6310 ].freeze # Replace with actual ship event IDs

  scope :needs_refill, -> {
    where("jsonb_array_length(ship_event_pairs) - current_position <= ?", REFILL_THRESHOLD)
  }

  def current_pair
    # Return tutorial pair if we should show tutorial content
    if should_show_tutorial_pair?
      return TUTORIAL_PAIR
    end

    return nil if queue_exhausted?
    Rails.logger.info("current post #{current_position}")

    ship_event_pairs[current_position]
  end

  def current_ship_events
    return [] unless current_pair
    Rails.logger.info("current pair #{current_pair}")

    @current_ship_events ||= ShipEvent.where(id: current_pair)
                                      .includes(:project)
                                      .order(:id)
  end

  def current_projects
    # Check if we should show tutorial pair for new onboarding users
    if should_show_tutorial_pair?
      return tutorial_projects
    end

    voted_se_ids = voted_ship_event_ids

    loop do
      ship_events = current_ship_events
      if ship_events.any? && ShipEvent.where(id: ship_events.map(&:id), excluded_from_pool: true).exists?
        advance_position!
        next
      end
      # excluse low quality projects
      if ship_events.any?
        over_reported_ids = FraudReport.unresolved.where(suspect_type: "ShipEvent", suspect_id: ship_events.map(&:id)).where("reason LIKE ?", "LOW_QUALITY:%").group(:suspect_id).having("COUNT(*) >= 3").count.keys
        if over_reported_ids.any? { |id| ship_events.map(&:id).include?(id) }
          advance_position!
          next
        end
      end
      projects = ship_events.map(&:project).compact

      # because of scope, this should filter for deleted projects
      if projects.size < 2

        # check for overflow
        if current_position + 1 >= ship_event_pairs.length
          refill_queue!(1)
        end

        advance_position!
        next
      end

      # skip if either ship event in the pair has already been voted on by the user
      if current_pair && (voted_se_ids.include?(current_pair[0]) || voted_se_ids.include?(current_pair[1]))
        advance_position!
        next
      end

      # voting queue might get stale and we might have two paid projects
      if both_paid?(ship_events)
        advance_position!
        next
      end

      # ensure total time covered for each project is greater than 0 seconds #ai hearbeats yoinked
      if zero_total_time_covered?(ship_events)
        advance_position!
        next
      end

      return projects
    end
  end

  # this should never happen - all generated matchups even in the queue should be unique
  def current_pair_voted?
    return false unless current_pair

    user.votes.exists?(
      ship_event_1_id: current_pair[0],
      ship_event_2_id: current_pair[1]
    )
  end

  def advance_position!
    return false if queue_exhausted?

    Rails.logger.info "Before increment: current_position = #{current_position}"
    result = increment!(:current_position)
    Rails.logger.info "After increment: current_position = #{current_position}, increment result = #{result}"

    @current_ship_events = nil

    if needs_refill?
      RefillUserVoteQueueJob.perform_later(user_id)
      refill_queue!(1)
    end

    true
  end

  def remaining_pairs
    [ ship_event_pairs.length - current_position, 0 ].max
  end

  def queue_exhausted?
    remaining_pairs == 0
  end

  def needs_refill?
    remaining_pairs <= REFILL_THRESHOLD
  end

  def refill_queue!(additional_pairs = QUEUE_SIZE)
    return 0 if additional_pairs <= 0

    existing_pair_keys = Set.new
    used_ids = Set.new
    ship_event_pairs.each do |x, y|
      a, b = x < y ? [ x, y ] : [ y, x ]
      existing_pair_keys << "#{a}:#{b}"
      used_ids << a << b
    end
    used_ids |= TUTORIAL_PAIR

    voted = voted_ship_event_ids
    excluded = used_ids | voted.to_set

    service = UserVoteQueueMatchupService
                .new(user_id: user_id, excluded_ship_event_ids: excluded)
                .build!
    return 0 if service.projects_with_time.empty? || service.unpaid_projects.empty?

    new_pairs = []
    (additional_pairs * 30).times do
      break if new_pairs.size >= additional_pairs
      pair = service.pick_pair(used_ship_event_ids: used_ids) or next

      a, b = pair
      a, b = b, a if a > b
      key = "#{a}:#{b}"

      next if existing_pair_keys.include?(key) || used_ids.include?(a) || used_ids.include?(b)

      existing_pair_keys << key
      used_ids << a << b
      new_pairs << [ a, b ]
    end

    update!(ship_event_pairs: ship_event_pairs + new_pairs, last_generated_at: Time.current) if new_pairs.any?
    new_pairs.size
  end

  def current_signature_valid?(signature)
    return false unless current_pair

    VoteSignatureService.verify_signature_with_ship_events(
      signature, current_pair[0], current_pair[1], user_id
    )[:valid]
  end

  def generate_current_signature
    return nil unless current_pair

    VoteSignatureService.generate_signature(
      current_pair[0], current_pair[1], user_id
    )
  end

  def should_show_tutorial_pair?
    # Only show tutorial pair if:
    # 1. New onboarding feature is enabled for the user
    # 2. Vote tutorial step is not completed
    # 3. Tutorial pair ship events exist
    return false unless Flipper.enabled?(:new_onboarding, user)
    return false if user.tutorial_progress&.new_tutorial_step_completed?("vote")
    return false unless tutorial_ship_events_exist?

    true
  end

  def tutorial_projects
    ship_events = ShipEvent.where(id: TUTORIAL_PAIR)
                           .includes(:project)
                           .order(:id)

    ship_events.map(&:project).compact
  end

  def tutorial_ship_events_exist?
    ShipEvent.where(id: TUTORIAL_PAIR).count == 2
  end

  private

  def both_paid?(ship_events)
    ids = ship_events.map(&:id)
    return false if ids.empty?

    paid_ids = Payout.where(payable_type: "ShipEvent", payable_id: ids)
                     .distinct
                     .pluck(:payable_id)
                     .to_set

    ship_events.all? { |se| paid_ids.include?(se.id) }
  end

  def zero_total_time_covered?(ship_events)
    ids = ship_events.map(&:id)
    totals_by_ship_event = Devlog
      .joins("INNER JOIN ship_events ON devlogs.project_id = ship_events.project_id")
      .where(ship_events: { id: ids })
      .where("devlogs.created_at <= ship_events.created_at")
      .group("ship_events.id")
      .sum(:duration_seconds)

    ship_events.any? { |se| (totals_by_ship_event[se.id] || 0) <= 0 }
  end

  def voted_ship_event_ids
    @voted_ship_event_ids ||= user.votes.distinct
                                  .pluck(:ship_event_1_id, :ship_event_2_id)
                                  .flatten
                                  .compact
  end
end
