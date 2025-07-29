class LeaderboardController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  def index
    @users = User.where(is_banned: false)
                 .order(Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) DESC"))
                 .limit(50)

    if current_user
      current_shells = current_user.balance
      @current_pos = User.where(is_banned: false)
        .where(Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) > ?"), current_shells)
        .count + 1
    end

    @projects = Project.order(rating: :desc).limit(25)

    @total_users = User.count
    @banned_users = User.where(is_banned: true).count
    @burned_amount = Payout.where(user_id: User.where(is_banned: true).select(:id)).where("amount > 0").sum(:amount)
    @marketcap = User.where(is_banned: false).joins(:payouts).group(:id).sum("payouts.amount").values.sum
  end
end
