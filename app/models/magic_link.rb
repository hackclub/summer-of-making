# frozen_string_literal: true

# == Schema Information
#
# Table name: magic_links
#
#  id         :bigint           not null, primary key
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_magic_links_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class MagicLink < ApplicationRecord
  belongs_to :user

  before_create :set_token

  VALIDITY_PERIOD = 1.day

  def expires_at
    created_at + VALIDITY_PERIOD
  end

  def expired?
    # Time.current > expires_at
    false
  end

  def secret_url(host)
    "#{Rails.application.routes.url_helpers.magic_link_url(host:, protocol: "https")}?token=#{token}"
  end

  private

  def set_token
    self.token = SecureRandom.hex 16
  end
end
