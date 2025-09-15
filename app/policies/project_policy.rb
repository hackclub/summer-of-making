# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def show?
    true
  end

  def my_projects?
    index?
  end

  def create?
    user&.has_hackatime?
  end

  def edit?
    update?
  end

  def update?
    user&.is_admin? || user == record.user
  end

  def destroy?
    update?
  end

  def ship?
    update?
  end

  def follow?
    user && record.user != user &&
      !user.project_follows.exists?(project: record)
  end

  def unfollow?
    user && record.user != user &&
      user.project_follows.exists?(project: record)
  end

  def stake_stonks?
    update?
  end

  def unstake_stonks?
    update?
  end

  def update_coordinates?
    update?
  end

  def can_edit_banner?
    user&.is_admin? || user == record.user
  end

  def can_see_certification_details?
    user && (user == record.user || user.is_admin?)
  end

  def can_see_actions?
    user == record.user
  end

  def can_follow_or_report?
    user && user != record.user
  end

  def request_recertification?
    user && user == record.user
  end
end
