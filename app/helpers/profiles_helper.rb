module ProfilesHelper
  def plan_usage_label(used:, limit:)
    return "#{used} used" if limit.blank?

    "#{used} of #{limit} used"
  end
end
