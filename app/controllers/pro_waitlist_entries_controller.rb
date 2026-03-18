class ProWaitlistEntriesController < ApplicationController
  before_action :set_pricing_context

  def create
    @waitlist_entry = ProWaitlistEntry.new(waitlist_entry_params)
    @waitlist_entry.user = Current.user

    if @waitlist_entry.save
      redirect_to pricing_path, notice: "You are on the #{Billing::PlanCatalog::PRO_DISPLAY_NAME} waitlist."
    else
      render "pricing/show", status: :unprocessable_entity
    end
  end

  private

  def set_pricing_context
    @feature_rows = Billing::PlanCatalog::FEATURE_ROWS
    @plan_options = Billing::PlanCatalog::PLAN_OPTIONS
    @billing_enabled = Billing::Config.configured?
  end

  def waitlist_entry_params
    params.require(:pro_waitlist_entry).permit(:email, :source, :plan_preference)
  end
end
