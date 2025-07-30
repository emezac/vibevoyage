# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription_plans, only: [:index, :show]

  def index
    @current_plan = current_user.subscription_plan || SubscriptionPlan.free_plan
    @journeys_remaining = current_user.journeys_remaining_this_month
  end

  def show
    @plan = SubscriptionPlan.find(params[:id])
    @current_plan = current_user.subscription_plan || SubscriptionPlan.free_plan
  end

  def subscribe
    @plan = SubscriptionPlan.find(params[:id])
    
    if @plan.free?
      # Downgrade to free plan
      current_user.update!(
        subscription_plan: @plan,
        subscription_status: 'free',
        subscription_expires_at: nil
      )
      redirect_to subscriptions_path, notice: 'Successfully switched to Free plan.'
    else
      # For paid plans, redirect to payment (you'll need to integrate Stripe/PayPal)
      redirect_to payment_path(@plan), notice: 'Redirecting to payment...'
    end
  end

  def cancel
    current_user.update!(
      subscription_status: 'canceled',
      subscription_expires_at: 1.month.from_now # Grace period
    )
    
    redirect_to subscriptions_path, notice: 'Subscription canceled. You can continue using premium features until the end of your billing period.'
  end

  private

  def set_subscription_plans
    @plans = SubscriptionPlan.active.by_price
  end

  # This would be implemented when you add payment processing
  def payment_path(plan)
    # Return Stripe/PayPal checkout URL
    "/payment/checkout?plan=#{plan.slug}"
  end
end
