class LeaderboardController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  def index
    @users = User.order(Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) DESC")).limit(50)

    if current_user
      c = current_user.balance
      @current_pos = User.where(
        Arel.sql("COALESCE((SELECT SUM(amount) FROM payouts WHERE payouts.user_id = users.id), 0) > ?"),
        c
      ).count + 1
    end

    @projects = Project.order(rating: :desc).limit(25)
  end
end
