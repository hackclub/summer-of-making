class Shop::KickVerificationLimboOrdersJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    orders = ShopOrder.in_verification_limbo.includes(:user)

    orders.each do |order|
      case order.user.verification_status
      when :verified
        order.user_was_verified
        order.save!
      when :ineligible
        order.mark_rejected("user is YSWS ineligible")
        order.save!
      else
        next
      end
    rescue StandardError => e
      Honeybadger.notify(e)
      next
    end
  end
end
