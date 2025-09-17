# frozen_string_literal: true

class ShopOrderPolicy < ApplicationPolicy
  def show?
    user && user == record.user
  end

  def create?
    user.present?
  end

  def index?
    user.present?
  end

  def edit?
    user&.is_admin?
  end

  def update?
    edit?
  end
end
