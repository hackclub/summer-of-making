# == Schema Information
#
# Table name: email_signups
#
#  id         :bigint           not null, primary key
#  email      :text             not null
#  ip         :inet
#  ref        :string
#  slack_id   :string
#  synced_at  :datetime
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_email_signups_on_email  (email) UNIQUE
#
class EmailSignup < ApplicationRecord
  # def self.dedupe
  #   # find all models and group them on keys which should be common
  #   grouped = all.group_by{|model| [model.email] }
  #   grouped.values.each do |duplicates|
  #     # the first one we want to keep right?
  #     first_one = duplicates.shift # or pop for last one
  #     # if there are any more left, they are duplicates
  #     # so delete all of them
  #     duplicates.each{|double| double.destroy} # duplicates can now be destroyed
  #   end
  # end
end
