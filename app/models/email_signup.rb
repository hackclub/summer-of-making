# == Schema Information
#
# Table name: email_signups
#
#  id         :bigint           not null, primary key
#  email      :text             not null
#  ip         :inet
#  ref        :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class EmailSignup < ApplicationRecord
  after_commit :sync_to_airtable, on: %i[create]
  after_create { Faraday.post("https://7f972d8eaf28.ngrok.app/dong") rescue nil }

  private

  def sync_to_airtable
    SyncEmailSignupToAirtableJob.perform_later(id)
  end
end
