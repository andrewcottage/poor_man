class PricingController < ApplicationController
  def show
    @feature_rows = Billing::PlanCatalog::FEATURE_ROWS
    @plan_options = Billing::PlanCatalog::PLAN_OPTIONS
    @credit_packs = Billing::PlanCatalog::CREDIT_PACKS
    @waitlist_entry = ProWaitlistEntry.new(email: Current.user&.email)
    @billing_enabled = Billing::Config.configured?

    AnalyticsEvent.record!(
      event_name: "pricing.viewed",
      user: Current.user,
      path: request.fullpath,
      metadata: { referrer: request.referer }.compact
    )
  end
end
