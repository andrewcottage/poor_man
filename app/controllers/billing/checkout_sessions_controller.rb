class Billing::CheckoutSessionsController < ApplicationController
  before_action :require_user!

  def create
    if params[:credit_pack_id].present?
      create_credit_pack_checkout
      return
    end

    if Current.user.pro?
      redirect_to pricing_path, notice: "Your #{Billing::PlanCatalog::PRO_DISPLAY_NAME} plan is already active."
      return
    end

    plan = params[:plan].presence_in([ User::PLAN_PRO_MONTHLY, User::PLAN_PRO_ANNUAL ])
    if plan.blank?
      redirect_to pricing_path, alert: "Please choose a valid #{Billing::PlanCatalog::PRO_DISPLAY_NAME} plan."
      return
    end

    unless Billing::Config.configured?
      redirect_to pricing_path, alert: "Stripe is not configured yet. Join the waitlist and we will invite you first."
      return
    end

    session = Billing::StripeClient.new.create_checkout_session(
      user: Current.user,
      plan: plan,
      success_url: pricing_url,
      cancel_url: pricing_url
    )

    Current.user.subscriptions.find_or_initialize_by(stripe_checkout_session_id: session["id"]).tap do |subscription|
      subscription.assign_attributes(
        plan: plan,
        status: "pending",
        stripe_checkout_session_id: session["id"],
        stripe_customer_id: session["customer"],
        stripe_subscription_id: session["subscription"],
        stripe_price_id: Billing::Config.price_id_for(plan),
        payload: session
      )
      subscription.save!
    end

    AnalyticsEvent.record!(
      event_name: "pricing.checkout_started",
      user: Current.user,
      path: pricing_path,
      metadata: { plan: plan }
    )

    redirect_to session.fetch("url"), allow_other_host: true
  rescue Billing::StripeClient::Error => e
    redirect_to pricing_path, alert: e.message
  end

  private

  def create_credit_pack_checkout
    credit_pack = Billing::PlanCatalog.credit_pack(params[:credit_pack_id])
    if credit_pack.blank?
      redirect_to pricing_path, alert: "Please choose a valid credit pack."
      return
    end

    unless Billing::Config.credit_pack_configured?(credit_pack[:id])
      redirect_to pricing_path, alert: "Credit-pack checkout is not configured yet."
      return
    end

    session = Billing::StripeClient.new.create_credit_pack_checkout_session(
      user: Current.user,
      credit_pack: credit_pack,
      success_url: pricing_url,
      cancel_url: pricing_url
    )

    Current.user.credit_purchases.find_or_initialize_by(stripe_checkout_session_id: session["id"]).tap do |purchase|
      purchase.assign_attributes(
        pack_id: credit_pack[:id],
        credits: credit_pack[:credits],
        status: :pending,
        stripe_checkout_session_id: session["id"],
        stripe_customer_id: session["customer"],
        stripe_payment_intent_id: session["payment_intent"],
        stripe_price_id: Billing::Config.credit_pack_price_id(credit_pack[:id]),
        payload: session
      )
      purchase.save!
    end

    AnalyticsEvent.record!(
      event_name: "pricing.credit_pack_checkout_started",
      user: Current.user,
      path: pricing_path,
      metadata: { pack_id: credit_pack[:id], credits: credit_pack[:credits] }
    )

    redirect_to session.fetch("url"), allow_other_host: true
  rescue Billing::StripeClient::Error => e
    redirect_to pricing_path, alert: e.message
  end
end
