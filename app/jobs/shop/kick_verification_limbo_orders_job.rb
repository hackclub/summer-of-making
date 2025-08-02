class Shop::KickVerificationLimboOrdersJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    orders = ShopOrder.in_verification_limbo.includes(:user)
    orders.find_each(order: :desc) do |order|
      vs = order.user.verification_status
      puts "Order #{order.id}: #{vs}"
      case vs
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
