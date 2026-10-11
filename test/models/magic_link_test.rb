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
require "test_helper"

class MagicLinkTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
