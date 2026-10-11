# frozen_string_literal: true

# == Schema Information
#
# Table name: likes
#
#  id            :bigint           not null, primary key
#  likeable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  likeable_id   :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_likes_on_likeable                                   (likeable_type,likeable_id)
#  index_likes_on_user_id                                    (user_id)
#  index_likes_on_user_id_and_likeable_type_and_likeable_id  (user_id,likeable_type,likeable_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class LikeTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
