module Billing
  class PlanCatalog
    PRO_DISPLAY_NAME = "Stovaro Pro"
    FREE_FAVORITES_LIMIT = 50
    FREE_COLLECTIONS_LIMIT = 1
    FREE_RECIPE_SUBMISSIONS_LIMIT = 5
    FREE_TRIAL_GENERATIONS = 1
    PRO_MONTHLY_GENERATION_LIMIT = 15
    CREDIT_PACKS = [
      {
        id: "extra_5",
        name: "5 extra generations",
        credits: 5,
        price: "$3.99",
        description: "For a quick burst of recipe ideation."
      },
      {
        id: "extra_15",
        name: "15 extra generations",
        credits: 15,
        price: "$9.99",
        description: "Best for bulk recipe creation and reworks."
      }
    ].freeze

    FEATURE_ROWS = [
      [ "Browse and search recipes", "Unlimited", "Unlimited" ],
      [ "Save favorites", "Up to #{FREE_FAVORITES_LIMIT}", "Unlimited" ],
      [ "Submit recipes", "Up to #{FREE_RECIPE_SUBMISSIONS_LIMIT}", "Unlimited" ],
      [ "Rate and review", "Unlimited", "Unlimited" ],
      [ "Collections / cookbooks", "#{FREE_COLLECTIONS_LIMIT} collection", "Unlimited" ],
      [ "AI recipe generation", "#{FREE_TRIAL_GENERATIONS} free trial", "#{PRO_MONTHLY_GENERATION_LIMIT} per month" ],
      [ "Meal planning calendar", "Coming soon", "Included in #{PRO_DISPLAY_NAME}" ],
      [ "Smart grocery lists", "Coming soon", "Included in #{PRO_DISPLAY_NAME}" ],
      [ "Nutrition information", "Coming soon", "Included in #{PRO_DISPLAY_NAME}" ],
      [ "Advanced search filters", "Standard", "Priority access" ]
    ].freeze

    PLAN_OPTIONS = [
      {
        id: User::PLAN_PRO_MONTHLY,
        name: "#{PRO_DISPLAY_NAME} Monthly",
        price: "$4.99",
        cadence: "per month"
      },
      {
        id: User::PLAN_PRO_ANNUAL,
        name: "#{PRO_DISPLAY_NAME} Annual",
        price: "$39.99",
        cadence: "per year"
      }
    ].freeze

    def self.credit_pack(id)
      CREDIT_PACKS.find { |pack| pack[:id] == id }
    end
  end
end
