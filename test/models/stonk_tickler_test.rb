# frozen_string_literal: true

# == Schema Information
#
# Table name: stonk_ticklers
#
#  id         :bigint           not null, primary key
#  tickler    :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  project_id :bigint           not null
#
# Indexes
#
#  index_stonk_ticklers_on_project_id  (project_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id) ON DELETE => cascade
#
require "test_helper"

class StonkTicklerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
