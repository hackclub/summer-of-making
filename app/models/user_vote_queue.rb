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

  scope :needs_refill, -> {
    where("jsonb_array_length(ship_event_pairs) - current_position <= ?", REFILL_THRESHOLD)
  }

  def current_pair
    return nil if queue_exhausted?
    Rails.logger.info("current post #{current_position}")

    ship_event_pairs[current_position]
  end

  def current_ship_events
    return [] unless current_pair
    Rails.logger.info("current pair #{current_pair}")

    ShipEvent.where(id: current_pair).includes(
      project: [
        :banner_attachment,
        devlogs: [ :user, :file_attachment ]
      ]
    ).order(:id)
  end

  def current_projects
    voted_se_ids = user.votes.distinct.pluck(:ship_event_1_id, :ship_event_2_id).flatten.compact

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
        next if replace_current_pair!
        advance_position!
        next
      end

      # voting queue might get stale and we might have two paid projects
      if both_paid?(ship_events)
        next if replace_current_pair!
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

    if needs_refill?
        refill_queue!
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
    new_pairs = []
    existing_pairs = ship_event_pairs.dup
    used_ship_event_ids = existing_pairs.flatten.to_set

    # i want to keep as is from the votes controller
    additional_pairs.times do
      pair = generate_matchup
      if pair &&
         !existing_pairs.include?(pair) &&
         !used_ship_event_ids.include?(pair[0]) &&
         !used_ship_event_ids.include?(pair[1])
        new_pairs << pair
        existing_pairs << pair
        used_ship_event_ids.add(pair[0])
        used_ship_event_ids.add(pair[1])
      end
    end

    if new_pairs.any?
      update!(
        ship_event_pairs: ship_event_pairs + new_pairs,
        last_generated_at: Time.current
      )
    end

    new_pairs.length
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

  private

  def both_paid?(ship_events)
    ship_events.all? { |se| se.payouts.exists? }
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

  def generate_matchup
    voted_ship_event_ids = user.votes.distinct.pluck(:ship_event_1_id, :ship_event_2_id).flatten.compact

    projects_with_latest_ship = Project
                                  .joins(:ship_events)
                                  .joins(:ship_certifications)
                                  .includes(ship_events: :payouts)
                                  .where(ship_certifications: { judgement: :approved })
                                  .where.not(user_id: user_id)
                                  .where(
                                    ship_events: {
                                      id: ShipEvent.select("MAX(ship_events.id)")
                                                  .where("ship_events.project_id = projects.id")
                                                  .group("ship_events.project_id")
                                                  .where.not(id: voted_ship_event_ids)
                                    }
                                  )
                                  .distinct

    return nil if projects_with_latest_ship.count < 2

    eligible_projects = projects_with_latest_ship.to_a

    latest_ship_event_ids = eligible_projects.map { |project|
      project.ship_events.where(excluded_from_pool: false).max_by(&:created_at)&.id
    }.compact

    # don't generate matchups for low quality projects
    flagged = FraudReport.unresolved.where(suspect_type: "ShipEvent", suspect_id: latest_ship_event_ids).where("reason LIKE ?", "LOW_QUALITY:%").group(:suspect_id).having("COUNT(*) >= 3").count.keys
    latest_ship_event_ids -= flagged

    total_times_by_ship_event = Devlog
      .joins("INNER JOIN ship_events ON devlogs.project_id = ship_events.project_id")
      .where(ship_events: { id: latest_ship_event_ids })
      .where("devlogs.created_at <= ship_events.created_at")
      .group("ship_events.id")
      .sum(:duration_seconds)

    projects_with_time = eligible_projects.map do |project|
      latest_ship_event = project.ship_events.max_by(&:created_at)
      total_time_seconds = total_times_by_ship_event[latest_ship_event.id] || 0
      is_paid = latest_ship_event.payouts.any?

      {
        project: project,
        total_time: total_time_seconds,
        ship_event: latest_ship_event,
        is_paid: is_paid,
        ship_date: latest_ship_event.created_at
      }
    end

    projects_with_time = projects_with_time.select { |p| p[:total_time] > 0 }

    # sort by ship date – disabled until genesis
    projects_with_time.sort_by! { |p| p[:ship_date] }

    unpaid_projects = projects_with_time.select { |p| !p[:is_paid] }
    paid_projects = projects_with_time.select { |p| p[:is_paid] }

    # we need at least 1 unpaid project and 1 other project (status doesn't matter)
    return nil if unpaid_projects.empty? || projects_with_time.size < 2

    selected_projects = []
    selected_project_data = []
    used_user_ids = Set.new
    used_repo_links = Set.new
    max_attempts = 25 # infinite loop!

    attempts = 0
    while selected_projects.size < 2 && attempts < max_attempts
      attempts += 1

      # pick a random unpaid project first
      if selected_projects.empty?
        available_unpaid = unpaid_projects.select { |p| !used_user_ids.include?(p[:project].user_id) && !used_repo_links.include?(p[:project].repo_link) }
        first_project_data = weighted_sample(available_unpaid)
        next unless first_project_data

        selected_projects << first_project_data[:project]
        selected_project_data << first_project_data
        used_user_ids << first_project_data[:project].user_id
        used_repo_links << first_project_data[:project].repo_link if first_project_data[:project].repo_link.present?
        first_time = first_project_data[:total_time]

        # find projects within the constraints (set to 30%)
        min_time = first_time * 0.7
        max_time = first_time * 1.3

        compatible_projects = projects_with_time.select do |p|
          !used_user_ids.include?(p[:project].user_id) &&
          !used_repo_links.include?(p[:project].repo_link) &&
          p[:total_time] >= min_time &&
          p[:total_time] <= max_time
        end

        if compatible_projects.any?
          second_project_data = weighted_sample(compatible_projects)
          selected_projects << second_project_data[:project]
          selected_project_data << second_project_data
          used_user_ids << second_project_data[:project].user_id
          used_repo_links << second_project_data[:project].repo_link if second_project_data[:project].repo_link.present?
        else
          selected_projects.clear
          selected_project_data.clear
          used_user_ids.clear
          used_repo_links.clear
        end
      end
    end

    # js getting smtth if after 25 attemps we have nothing
    if selected_projects.size < 2 && unpaid_projects.any?
      first_project_data = weighted_sample(unpaid_projects)
      remaining_projects = projects_with_time.reject { |p|
        p[:project].user_id == first_project_data[:project].user_id ||
        (p[:project].repo_link.present? && p[:project].repo_link == first_project_data[:project].repo_link)
      }

      if remaining_projects.any?
        second_project_data = weighted_sample(remaining_projects)
        selected_projects = [ first_project_data[:project], second_project_data[:project] ]
        selected_project_data = [ first_project_data, second_project_data ]
      end
    end

    return nil if selected_projects.size < 2

    # Return the ship event pair (normalized with smaller ID first)
    ship_event_1_id = selected_project_data[0][:ship_event].id
    ship_event_2_id = selected_project_data[1][:ship_event].id

    if ship_event_1_id > ship_event_2_id
      ship_event_1_id, ship_event_2_id = ship_event_2_id, ship_event_1_id
    end

    [ ship_event_1_id, ship_event_2_id ]
  end

  def weighted_sample(projects)
    return nil if projects.empty?
    return projects.first if projects.size == 1

    # Weight decreases exponentially: first project gets weight 1.0, second gets 0.95, etc.
    weights = projects.map.with_index { |_, index| 0.95 ** index }
    total_weight = weights.sum

    random = rand * total_weight
    cumulative_weight = 0

    projects.each_with_index do |project, index|
      cumulative_weight += weights[index]
      return project if random <= cumulative_weight
    end

    projects.first
  end

  def replace_current_pair!
    return false if queue_exhausted? || current_pair.nil?

    used_ship_event_ids = ship_event_pairs.each_with_index.flat_map { |p, idx| idx == current_position ? [] : p }.to_set

    10.times do
      pair = generate_matchup
      next unless pair
      next if used_ship_event_ids.include?(pair[0]) || used_ship_event_ids.include?(pair[1])

      new_pairs = ship_event_pairs.dup
      new_pairs[current_position] = pair
      update!(ship_event_pairs: new_pairs, last_generated_at: Time.current)
      return true
    end

    false
  end
end
