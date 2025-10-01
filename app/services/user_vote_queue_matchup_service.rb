# frozen_string_literal: true

require "set"

class UserVoteQueueMatchupService
  def initialize(user_id:, excluded_ship_event_ids: [])
    @user_id = user_id
    @excluded_ship_event_ids = Array(excluded_ship_event_ids)
    @projects_with_time = []
    @unpaid_projects = []
    @mature_unpaid_projects = []
    @immature_unpaid_projects = []
    @paid_projects = []
  end

  attr_reader :projects_with_time, :unpaid_projects,
              :mature_unpaid_projects, :immature_unpaid_projects, :paid_projects

  def build!
    latest_eligible = ShipEvent
                        .joins(project: :ship_certifications)
                        .where(ship_certifications: { judgement: :approved })
                        .where.not(projects: { user_id: @user_id })
                        .where(excluded_from_pool: false)
                        .where.not(id: @excluded_ship_event_ids)
                        .select("DISTINCT ON (ship_events.project_id) ship_events.id, ship_events.project_id, ship_events.created_at")
                        .order("ship_events.project_id, ship_events.id DESC")

    return self unless latest_eligible.offset(1).exists?

    rows = latest_eligible.to_a.map { |se| [ se.project_id, se.id, se.created_at ] }

    latest_by_project = {}
    ship_dates_by_project = {}
    rows.each do |project_id, ship_event_id, created_at|
      latest_by_project[project_id] = ship_event_id
      ship_dates_by_project[project_id] = created_at
    end

    eligible_project_rows = Project.where(id: latest_by_project.keys).pluck(:id, :user_id, :repo_link)
    latest_ship_event_ids = latest_by_project.values

    total_times_by_ship_event = Devlog
      .joins("INNER JOIN ship_events ON devlogs.project_id = ship_events.project_id")
      .where(ship_events: { id: latest_ship_event_ids })
      .where("devlogs.created_at <= ship_events.created_at")
      .group("ship_events.id")
      .sum(:duration_seconds)

    paid_ids = Payout.where(payable_type: "ShipEvent", payable_id: latest_ship_event_ids)
                     .distinct
                     .pluck(:payable_id)
                     .to_set

    vote_counts_by_ship_event = Hash.new(0)
    votes_col1 = Vote.active.where(ship_event_1_id: latest_ship_event_ids).group(:ship_event_1_id).count
    votes_col2 = Vote.active.where(ship_event_2_id: latest_ship_event_ids).group(:ship_event_2_id).count
    votes_col1.each { |id, count| vote_counts_by_ship_event[id] += count }
    votes_col2.each { |id, count| vote_counts_by_ship_event[id] += count }

    @projects_with_time = eligible_project_rows.filter_map do |project_id, project_user_id, project_repo_link|
      latest_id = latest_by_project[project_id]
      next unless latest_id
      total_time_seconds = total_times_by_ship_event[latest_id] || 0
      next unless total_time_seconds.positive?

      {
        project_id: project_id,
        user_id: project_user_id,
        repo_link: project_repo_link,
        total_time: total_time_seconds,
        ship_event_id: latest_id,
        is_paid: paid_ids.include?(latest_id),
        votes_count: vote_counts_by_ship_event[latest_id].to_i,
        ship_date: ship_dates_by_project[project_id]
      }
    end
    @projects_with_time.sort_by! { |p| p[:ship_date] }
    Rails.logger.info("projects_with_time: #{@projects_with_time.map { |p| [ p[:project_id], p[:votes_count] ] }}")

    @unpaid_projects = @projects_with_time.select { |p| !p[:is_paid] }
    @paid_projects = @projects_with_time.select { |p| p[:is_paid] }
    @mature_unpaid_projects = @projects_with_time.select { |p| p[:votes_count].to_i >= 12 && !p[:is_paid] }
    @immature_unpaid_projects = @projects_with_time.select { |p| p[:votes_count].to_i < 12 && !p[:is_paid] }
    self
  end

  def pick_pair(used_ship_event_ids: Set.new)
    return nil if @unpaid_projects.empty? || @projects_with_time.size < 2

    selected_project_data = []
    used_user_ids = Set.new
    used_repo_links = Set.new

    attempts = 0
    max_attempts = 25
    while selected_project_data.size < 2 && attempts < max_attempts
      attempts += 1

      if selected_project_data.empty?
        # First pick: unpaid and immature (< 12 votes) (kinda borrowing uncertaiity from bayseain systems but not really)
        available_unpaid_immature = @immature_unpaid_projects.select { |p| eligible_for_selection?(p, used_user_ids, used_repo_links, used_ship_event_ids) }
        available_unpaid_immature = @unpaid_projects.select { |p| eligible_for_selection?(p, used_user_ids, used_repo_links, used_ship_event_ids) } if available_unpaid_immature.empty?
        first_project_data = weighted_sample(available_unpaid_immature)
        next unless first_project_data

        selected_project_data << first_project_data
        used_user_ids << first_project_data[:user_id]
        used_repo_links << first_project_data[:repo_link] if first_project_data[:repo_link].present?

        first_time = first_project_data[:total_time]
        min_time = first_time * 0.7
        max_time = first_time * 1.3

        compatible_mature_unpaid = @mature_unpaid_projects.select { |p| eligible_for_selection?(p, used_user_ids, used_repo_links, used_ship_event_ids) && time_compatible?(p, min_time, max_time) }
        if compatible_mature_unpaid.any?
          second_project_data = weighted_sample(compatible_mature_unpaid)
          selected_project_data << second_project_data
          used_user_ids << second_project_data[:user_id]
          used_repo_links << second_project_data[:repo_link] if second_project_data[:repo_link].present?
        else
          compatible_paid = @paid_projects.select { |p| eligible_for_selection?(p, used_user_ids, used_repo_links, used_ship_event_ids) && time_compatible?(p, min_time, max_time) }
          if compatible_paid.any?
            second_project_data = weighted_sample(compatible_paid)
            selected_project_data << second_project_data
            used_user_ids << second_project_data[:user_id]
            used_repo_links << second_project_data[:repo_link] if second_project_data[:repo_link].present?
          else
            selected_project_data.clear
            used_user_ids.clear
            used_repo_links.clear
          end
        end
      end
    end

    if selected_project_data.size < 2 && @unpaid_projects.any?
      eligible_unpaid = @unpaid_projects.reject { |p| used_ship_event_ids.include?(p[:ship_event_id]) }
      first_project_data = weighted_sample(eligible_unpaid)
      return nil unless first_project_data
      remaining_projects = @projects_with_time.reject { |p|
        p[:user_id] == first_project_data[:user_id] ||
        (p[:repo_link].present? && p[:repo_link] == first_project_data[:repo_link]) ||
        used_ship_event_ids.include?(p[:ship_event_id])
      }
      if remaining_projects.any?
        second_project_data = weighted_sample(remaining_projects)
        selected_project_data = [ first_project_data, second_project_data ]
      end
    end

    if selected_project_data.size < 2 && !@unpaid_projects.any?
      eligible_paid = @paid_projects.reject { |p| used_ship_event_ids.include?(p[:ship_event_id]) }
      eligible_paid = @projects_with_time.reject { |p| used_ship_event_ids.include?(p[:ship_event_id]) } if eligible_paid.empty?
      first_project_data = weighted_sample(eligible_paid)
      return nil unless first_project_data
      remaining_projects = @projects_with_time.reject { |p|
        p[:user_id] == first_project_data[:user_id] ||
        (p[:repo_link].present? && p[:repo_link] == first_project_data[:repo_link]) ||
        used_ship_event_ids.include?(p[:ship_event_id])
      }
      if remaining_projects.any?
        second_project_data = weighted_sample(remaining_projects)
        selected_project_data = [ first_project_data, second_project_data ]
      end
    end

    return nil if selected_project_data.size < 2

    selected_project_data.map { |p| p[:ship_event_id] }.minmax
  end

  private

  def eligible_for_selection?(project, used_user_ids, used_repo_links, used_ship_event_ids)
    !used_user_ids.include?(project[:user_id]) &&
      !used_repo_links.include?(project[:repo_link]) &&
      !used_ship_event_ids.include?(project[:ship_event_id])
  end

  def time_compatible?(project, min_time, max_time)
    project[:total_time] >= min_time && project[:total_time] <= max_time
  end

  def weighted_sample(projects)
    return nil if projects.empty?
    return projects.first if projects.size == 1

    weights = projects.map.with_index { |_, index| 0.60 ** index }
    total_weight = weights.sum

    random = rand * total_weight
    cumulative_weight = 0

    projects.each_with_index do |project, index|
      cumulative_weight += weights[index]
      return project if random <= cumulative_weight
    end

    projects.first
  end
end
