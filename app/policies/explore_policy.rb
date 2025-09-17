class ExplorePolicy < ApplicationPolicy
  def index?
    true
  end

  def following?
    user.present?
  end

  def gallery?
    true
  end
end
