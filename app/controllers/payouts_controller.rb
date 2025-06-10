class PayoutsController < ApplicationController
  before_action :verify_fraud_token, if: -> { request.format.json? }

  def index
    respond_to do |format|
      format.json do
        user = User.find_by(slack_id: params[:slack_id])
        return render json: { error: 'User not found' }, status: :not_found unless user
        
        render json: {
          balance: user.balance,
          payouts: user.payouts,
        }
      end
      format.html { @payouts = current_user.payouts }
    end
  end

  def balance
    user = User.find_by(slack_id: params[:slack_id])

    render json: {
      balance: user.balance,
      payouts: user.payouts,
    }
  end

  private

  def verify_fraud_token
    unless params[:token] == Rails.application.credentials.fraud.token
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
