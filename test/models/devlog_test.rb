# frozen_string_literal: true

# == Schema Information
#
# Table name: devlogs
#
#  id                              :bigint           not null, primary key
#  attachment                      :string
#  comments_count                  :integer          default(0), not null
#  deleted_at                      :datetime
#  duration_seconds                :integer          default(0), not null
#  for_sinkening                   :boolean          default(FALSE), not null
#  hackatime_projects_key_snapshot :jsonb            not null
#  hackatime_pulled_at             :datetime
#  is_neighborhood_migrated        :boolean          default(FALSE), not null
#  last_hackatime_time             :integer
#  likes_count                     :integer          default(0), not null
#  seconds_coded                   :integer
#  text                            :text
#  views_count                     :integer          default(0), not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  project_id                      :bigint           not null
#  user_id                         :bigint           not null
#
# Indexes
#
#  index_devlogs_on_deleted_at   (deleted_at)
#  index_devlogs_on_project_id   (project_id)
#  index_devlogs_on_user_id      (user_id)
#  index_devlogs_on_views_count  (views_count)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class DevlogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
