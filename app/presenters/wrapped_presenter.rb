# frozen_string_literal: true

class WrappedPresenter
  HELPER_STATS_MISS = :__wrapped_helper_stats_miss

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def shells_earned
    @shells_earned ||= user.shells_earned
  end

  def shells_spent
    @shells_spent ||= user.shells_spent.to_i
  end

  def net_shells
    shells_earned - shells_spent
  end

  def usd_spent_by_hack_club
    @usd_spent_by_hack_club ||= user.usd_spent_by_hack_club
  end

  def most_expensive_order
    @most_expensive_order ||= user.most_expensive_order
  end

  def most_expensive_order_total
    return 0 unless most_expensive_order

    (most_expensive_order.frozen_item_price.to_f * most_expensive_order.quantity.to_i)
  end

  def most_expensive_item
    @most_expensive_item ||= user.most_expensive_item
  end

  def most_expensive_item_price
    return nil unless most_expensive_item

    @most_expensive_item_price ||= begin
      value = user.shop_orders
                   .worth_counting
                   .where(shop_item: most_expensive_item)
                   .order(Arel.sql("frozen_item_price DESC NULLS LAST"))
                   .limit(1)
                   .pluck(:frozen_item_price)
                   .first
      value&.to_f
    end
  end

  def project_with_most_time
    @project_with_most_time ||= user.project_with_most_time
  end

  def project_with_highest_shells_per_hour
    @project_with_highest_shells_per_hour ||= user.project_with_highest_shells_per_hour
  end

  def project_total_seconds(project)
    return nil unless project

    @project_total_seconds ||= {}
    @project_total_seconds[project.id] ||= project.total_seconds_coded
  end

  def project_total_hours(project)
    seconds = project_total_seconds(project)
    return nil unless seconds.to_i.positive?

    seconds / 3600.0
  end

  def project_shells_earned(project)
    return nil unless project

    @project_shells ||= {}
    @project_shells[project.id] ||= user.payouts
                                         .where(payable: project.ship_events)
                                         .sum(:amount)
                                         .to_f
  end

  def project_shells_per_hour(project)
    hours = project_total_hours(project)
    shells = project_shells_earned(project)
    return nil unless hours && shells

    (shells / hours).round(2)
  end

  def helper_slide?
    stats = helper_ticket_stats
    return false unless stats

    stats[:helper] && stats[:tickets_closed].to_i.positive?
  end

  def helper_tickets_closed
    stats = helper_ticket_stats
    return nil unless stats

    stats[:tickets_closed].to_i
  end

  def helper_tickets_opened
    stats = helper_ticket_stats
    return nil unless stats

    stats[:tickets_opened].to_i
  end

  def votes_cast
    if user.respond_to?(:votes_count) && !user.votes_count.nil?
      user.votes_count.to_i
    else
      user.votes.count
    end
  end

  private

  def helper_ticket_stats
    return @helper_ticket_stats if defined?(@helper_ticket_stats)
    return @helper_ticket_stats = nil unless user.slack_id.present?

    cache_key = "wrapped/helper_stats/#{user.slack_id}"
    cached = Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      fetch_helper_ticket_stats || HELPER_STATS_MISS
    end

    @helper_ticket_stats = cached == HELPER_STATS_MISS ? nil : cached
  end

  def fetch_helper_ticket_stats
    response = Faraday.get(
      "https://nephthys.hackclub.com/api/user",
      { id: user.slack_id },
      { "Accept" => "application/json" }
    )

    return nil unless response.success?

    data = JSON.parse(response.body)
    return nil unless data.is_a?(Hash)

    data.deep_symbolize_keys
  rescue StandardError => e
    Rails.logger.warn("Wrapped helper stats error for user #{user.id}: #{e.class} #{e.message}")
    nil
  end
end
