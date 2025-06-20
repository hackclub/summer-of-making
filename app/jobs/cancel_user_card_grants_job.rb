# frozen_string_literal: true

class CancelUserCardGrantsJob < ApplicationJob
  def perform(user)
    user.shop_card_grants.find_each do |card_grant|
      next unless card_grant.hcb_grant_hashid.present?

      begin
        HCBService.cancel_card_grant!(hashid: card_grant.hcb_grant_hashid)
        Rails.logger.info "Cancelled card grant #{card_grant.hcb_grant_hashid} for user #{user.id}"
      rescue => e
        Rails.logger.error "Failed to cancel card grant #{card_grant.hcb_grant_hashid} for user #{user.id}: #{e.message}"
        raise e
      end
    end
  end
end
