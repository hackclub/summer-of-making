# == Schema Information
#
# Table name: shipwright_advices
#
#  id                    :bigint           not null, primary key
#  completed_at          :datetime
#  description           :text
#  proof_link            :string
#  shell_reward          :integer          default(0)
#  status                :integer          default("pending")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  project_id            :bigint           not null
#  ship_certification_id :bigint           not null
#
# Indexes
#
#  index_shipwright_advices_on_project_id             (project_id)
#  index_shipwright_advices_on_project_id_and_status  (project_id,status)
#  index_shipwright_advices_on_ship_certification_id  (ship_certification_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (ship_certification_id => ship_certifications.id)
#
require "test_helper"

class ShipwrightAdviceTest < ActiveSupport::TestCase
end
