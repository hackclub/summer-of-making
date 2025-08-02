class LeaderboardController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  def index
    @users = User.where(is_banned: false)
                 .includes(:payouts)
                 .order(Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) DESC"))
                 .limit(50)

    if current_user
      current_shells = current_user.balance
      @current_pos = User.where(is_banned: false)
        .where(Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) > ?"), current_shells)
        .count + 1
    end

    @projects = Project.order(rating: :desc)
                       .includes(:banner_attachment)
                       .limit(25)

    @total_users = User.count
    @banned_users = User.where(is_banned: true).count
    @burned_amount = Payout.where(user_id: User.where(is_banned: true).select(:id)).where("amount > 0").sum(:amount)
    @marketcap = User.where(is_banned: false).joins(:payouts).group(:id).sum("payouts.amount").values.sum

    @shoplb = ShopItem
      .not_black_market
      .joins(:shop_orders)
      .includes(:image_attachment)
      .select("shop_items.*, SUM(shop_orders.quantity) AS total_purchased")
      .group("shop_items.id")
      .order("total_purchased DESC")
      .limit(25)
  end
end
