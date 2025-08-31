module Admin
  class PayoutsDashboardController < ApplicationController
    before_action :admin_required

    def index
      @cap = Payout.sum(:amount)

      yesterday = 24.hours.ago
      recent = Payout.where(created_at: yesterday..)

      @created = recent.where("amount > 0").sum(:amount)
      @destroyed = recent.where("amount < 0").sum(:amount).abs
      @txns = recent.count
      @volume = recent.sum("ABS(amount)")

      spenders = Payout.joins(:user)
                      .where(created_at: yesterday.., amount: ...0, payable_type: "ShopOrder")
                      .group("users.id", "users.display_name", "users.avatar")
                      .sum("payouts.amount")

      @spenders = spenders.map { |user_data, amount| [ user_data, amount.abs ] }
                         .sort_by { |_, amount| -amount }
                         .first(10)

      holder_balances = Payout.joins(:user)
                             .group("users.id", "users.display_name", "users.avatar")
                             .sum(:amount)
                             .select { |_, balance| balance > 0 }
                             .sort_by { |_, balance| -balance }
                             .first(10)

      @holders = holder_balances

      @sources = {}
      recent.group(:payable_type).group("amount > 0").sum(:amount).each do |key, amount|
        @sources[key] = amount
      end

      thirty_days_ago = 30.days.ago.beginning_of_day
      daily_data = Payout.where(created_at: thirty_days_ago..)
                         .group("DATE(created_at)")
                         .group("CASE WHEN amount >= 0 THEN 'created' ELSE 'destroyed' END")
                         .sum("ABS(amount)")

      @creation = {}
      @destruction = {}

      30.times do |i|
        date = i.days.ago.to_date
        date_str = date.to_s
        @creation[date] = daily_data[[ date_str, "created" ]] || 0
        @destruction[date] = daily_data[[ date_str, "destroyed" ]] || 0
      end

      circulation_data = Payout.where("created_at < ?", 31.days.ago.beginning_of_day)
                              .sum(:amount)

      daily_changes = Payout.where(created_at: thirty_days_ago..)
                           .group("DATE(created_at)")
                           .sum(:amount)

      @circulation = {}
      total = circulation_data

      30.times do |i|
        date = i.days.ago.to_date
        change = daily_changes[date.to_s] || 0
        total += change
        @circulation[date] = total
      end

      @creation = @creation.sort.to_h
      @destruction = @destruction.sort.to_h
      @circulation = @circulation.sort.to_h

      @types = {}
      Payout.where(created_at: 7.days.ago..).group(:payable_type).sum("ABS(amount)").each do |type, volume|
        @types[type&.humanize || "Unknown"] = volume
      end

      @recent = Payout.includes(:user, :payable)
                             .order(created_at: :desc)
                             .limit(100)

      escrow_scope = Payout.where(escrowed: true)
      @escrow_count = escrow_scope.count
      @escrow_amount = escrow_scope.sum(:amount)
      @escrow_recent_amount = escrow_scope.where(created_at: yesterday..).sum(:amount)
      @escrow_users = escrow_scope.distinct.count(:user_id)
      @released_cap = Payout.where(escrowed: false).sum(:amount)

      escrow_holder_balances = Payout.joins(:user)
                                     .where(escrowed: true)
                                     .group("users.id", "users.display_name", "users.avatar")
                                     .sum(:amount)
      @escrow_holders = escrow_holder_balances
                          .sort_by { |_, amount| -amount }
                          .first(10)

      holder_user_ids = @escrow_holders.map { |(user_data, _)| user_data[0] }
      users_for_holders = User.where(id: holder_user_ids).includes(:votes, projects: :ship_events)
      @votes_needed_by_user_id = users_for_holders.to_h do |u|
        remaining = [ u.votes_required_for_release - u.votes.active.count, 0 ].max
        [ u.id, remaining ]
      end

      @escrow_release_ready = 0
      escrow_user_ids = escrow_scope.select(:user_id).distinct.pluck(:user_id)
      if escrow_user_ids.any?
        User.where(id: escrow_user_ids).find_each do |u|
          @escrow_release_ready += 1 if u.has_met_voting_requirement?
        end
      end
      @total_votes_needed = 0
      if escrow_user_ids.any?
        User.where(id: escrow_user_ids).find_each do |u|
          @total_votes_needed += [ u.votes_required_for_release - u.votes.active.count, 0 ].max
        end
      end

      approved_project_ids = Project.joins(:ship_certifications)
                                    .where(ship_certifications: { judgement: :approved })
                                    .distinct
                                    .pluck(:id)

      @total_ship_events = ShipEvent.where(project_id: approved_project_ids).count
      released_ship_event_ids = Payout.joins("JOIN ship_events ON payouts.payable_id = ship_events.id")
                                      .where(payable_type: "ShipEvent", escrowed: false)
                                      .where(ship_events: { project_id: approved_project_ids })
                                      .distinct
                                      .pluck(:payable_id)
      any_payout_ship_event_ids = Payout.joins("JOIN ship_events ON payouts.payable_id = ship_events.id")
                                        .where(payable_type: "ShipEvent")
                                        .where(ship_events: { project_id: approved_project_ids })
                                        .distinct
                                        .pluck(:payable_id)

      @total_unpaid_ship_events = ShipEvent.where(project_id: approved_project_ids)
                                           .where.not(id: any_payout_ship_event_ids)
                                           .count

      escrowed_only_ship_event_ids = (Payout.joins("JOIN ship_events ON payouts.payable_id = ship_events.id")
                                            .where(payable_type: "ShipEvent", escrowed: true)
                                            .where(ship_events: { project_id: approved_project_ids })
                                            .distinct.pluck(:payable_id) - released_ship_event_ids)
      @escrow_pending_ship_events = ShipEvent.where(id: escrowed_only_ship_event_ids, project_id: approved_project_ids).count

      last_paid_payout = Payout.where(payable_type: "ShipEvent", escrowed: false)
                               .order(created_at: :desc)
                               .includes(:payable)
                               .first
      @rough_next_ship_date = last_paid_payout&.payable&.created_at
    end

    private

    def admin_required
      redirect_to root_path unless current_user&.is_admin?
    end
  end
end
