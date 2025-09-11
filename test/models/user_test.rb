# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                                   :bigint           not null, primary key
#  avatar                               :string
#  badges                               :string           default([]), is an Array
#  display_name                         :string
#  email                                :string
#  first_name                           :string
#  fraud_team_member                    :boolean          default(FALSE), not null
#  freeze_shop_activity                 :boolean          default(FALSE)
#  has_black_market                     :boolean
#  has_clicked_completed_tutorial_modal :boolean          default(FALSE), not null
#  has_commented                        :boolean          default(FALSE)
#  has_hackatime                        :boolean          default(FALSE)
#  has_hackatime_account                :boolean
#  identity_vault_access_token          :string
#  internal_notes                       :text
#  is_admin                             :boolean          default(FALSE), not null
#  is_banned                            :boolean          default(FALSE)
#  last_name                            :string
#  permissions                          :text             default([])
#  shenanigans_state                    :jsonb
#  synced_at                            :datetime
#  timezone                             :string
#  tutorial_video_seen                  :boolean          default(FALSE), not null
#  ysws_verified                        :boolean          default(FALSE)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  identity_vault_id                    :string
#  slack_id                             :string
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
