# == Schema Information
#
# Table name: users
#
#  id                         :integer          not null, primary key
#  admin                      :boolean
#  api_key                    :string
#  email                      :string           not null
#  free_generation_used_at    :datetime
#  generation_credits_balance :integer          default(0), not null
#  generations_count          :integer          default(0), not null
#  generations_reset_at       :datetime
#  name                       :string
#  password_digest            :string
#  plan                       :string           default("free"), not null
#  plan_expires_at            :datetime
#  provider                   :string
#  recovery_digest            :string
#  uid                        :string
#  username                   :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  stripe_customer_id         :string
#  stripe_subscription_id     :string
#
# Indexes
#
#  index_users_on_api_key                 (api_key) UNIQUE
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_plan                    (plan)
#  index_users_on_stripe_customer_id      (stripe_customer_id)
#  index_users_on_stripe_subscription_id  (stripe_subscription_id)
#  index_users_on_username                (username) UNIQUE
#
class User < ApplicationRecord
  PLAN_FREE = "free"
  PLAN_PRO_MONTHLY = "pan_pro_monthly"
  PLAN_PRO_ANNUAL = "pan_pro_annual"

  has_secure_password

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest
  end

  before_validation :ensure_username

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  normalizes :email, with: ->(email) { email.downcase }

  attribute :admin, :boolean, default: false
  attribute :api_key, default: -> { SecureRandom.hex(15) }

  has_many :recipes, foreign_key: "author_id", dependent: :nullify
  has_many :recipe_generations, class_name: "Recipe::Generation", dependent: :destroy
  has_many :ratings
  has_many :favorites
  has_many :favorite_recipes, through: :favorites, source: :recipe
  has_many :subscriptions, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :collection_recipes, through: :collections
  has_many :analytics_events, dependent: :nullify
  has_many :credit_purchases, dependent: :destroy
  has_many :pro_waitlist_entries, dependent: :nullify
  has_many :meal_plans, dependent: :destroy
  has_many :planned_meals, through: :meal_plans
  has_many :grocery_lists, dependent: :destroy
  has_many :chat_conversations, class_name: "Chat::Conversation", dependent: :destroy
  has_many :active_follows, class_name: "UserFollow", foreign_key: :follower_id, dependent: :destroy
  has_many :passive_follows, class_name: "UserFollow", foreign_key: :followed_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  has_one_attached :avatar

  validates :plan, inclusion: {
    in: [ PLAN_FREE, PLAN_PRO_MONTHLY, PLAN_PRO_ANNUAL ]
  }

  def self.default_author
    User.where(admin: true).first
  end

  def self.from_omniauth(auth)
    User.find_or_create_by(uid: auth["uid"], provider: auth["provider"]) do |u|
      auth_email = auth.dig("info", "email")
      u.email = auth_email
      u.username = auth_email.split("@").first
      u.password = SecureRandom.hex(15)
    end
  end

  def free?
    !pro?
  end

  def pro?
    admin? || (paid_plan? && (plan_expires_at.blank? || plan_expires_at.future?))
  end

  def plan_label
    case plan
    when PLAN_PRO_MONTHLY
      "#{Billing::PlanCatalog::PRO_DISPLAY_NAME} Monthly"
    when PLAN_PRO_ANNUAL
      "#{Billing::PlanCatalog::PRO_DISPLAY_NAME} Annual"
    else
      "Free"
    end
  end

  def favorite_limit
    free? ? Billing::PlanCatalog::FREE_FAVORITES_LIMIT : nil
  end

  def collection_limit
    free? ? Billing::PlanCatalog::FREE_COLLECTIONS_LIMIT : nil
  end

  def recipe_submission_limit
    free? ? Billing::PlanCatalog::FREE_RECIPE_SUBMISSIONS_LIMIT : nil
  end

  def remaining_recipe_generations
    included_recipe_generations_remaining + generation_credits_balance
  end

  def included_recipe_generations_remaining
    if pro?
      [ Billing::PlanCatalog::PRO_MONTHLY_GENERATION_LIMIT - effective_generations_count, 0 ].max
    else
      free_generation_used_at.present? ? 0 : Billing::PlanCatalog::FREE_TRIAL_GENERATIONS
    end
  end

  def remaining_generation_credits
    generation_credits_balance
  end

  def generation_window_label
    return "lifetime trial" if free?
    return "renews with your next billing cycle" if generations_reset_at.blank?

    "resets #{I18n.l(generations_reset_at.to_date, format: :long)}"
  end

  def can_add_favorite?
    within_limit?(favorites.count, favorite_limit)
  end

  def can_create_collection?
    within_limit?(collections.count, collection_limit)
  end

  def can_submit_recipe?
    within_limit?(recipes.count, recipe_submission_limit)
  end

  def can_generate_recipe?
    remaining_recipe_generations.positive?
  end

  def consume_recipe_generation!
    with_lock do
      return false unless can_generate_recipe?

      if included_recipe_generations_remaining.positive?
        if pro?
          reset_generation_allowance_if_needed!
          self.generations_count = effective_generations_count + 1
        else
          self.generations_count += 1
          self.free_generation_used_at ||= Time.current
        end
      else
        self.generation_credits_balance -= 1
      end

      save!
    end

    true
  end

  def collections_for(recipe)
    collections.joins(:collection_recipes).where(collection_recipes: { recipe_id: recipe.id }).distinct
  end

  def follows?(other_user)
    following.exists?(id: other_user.id)
  end

  def contributor_badge
    return "Founder" if admin?

    case reputation_score
    when 50..Float::INFINITY
      "Kitchen Mentor"
    when 20...50
      "Trusted Cook"
    when 8...20
      "Active Contributor"
    else
      "Community Cook"
    end
  end

  def reputation_score
    recipe_points = recipes.approved.count * 3
    review_points = ratings.count * 2
    follower_points = followers.count * 4
    rating_points = recipes.joins(:ratings).average(:value).to_f.round

    recipe_points + review_points + follower_points + rating_points
  end

  def recent_public_activity(limit: 8)
    Community::Feed.call(limit: limit * 2).select { |activity| activity.user == self }.first(limit)
  end

  def self.trending_contributors(limit: 6)
    left_joins(:recipes, :passive_follows)
      .group("users.id")
      .order(Arel.sql("COUNT(DISTINCT recipes.id) DESC, COUNT(DISTINCT user_follows.id) DESC, users.created_at DESC"))
      .limit(limit)
  end

  private

  def paid_plan?
    plan.in?([ PLAN_PRO_MONTHLY, PLAN_PRO_ANNUAL ])
  end

  def effective_generations_count
    return 0 if pro? && reset_generation_allowance?

    generations_count
  end

  def reset_generation_allowance?
    generations_reset_at.blank? || generations_reset_at <= Time.current
  end

  def reset_generation_allowance_if_needed!
    return unless pro?
    return unless reset_generation_allowance?

    self.generations_count = 0
    self.generations_reset_at = 1.month.from_now
  end

  def within_limit?(count, limit)
    return true if limit.blank?

    count < limit
  end

  def ensure_username
    return if username.present? || email.blank?

    self.username = email.split("@").first.parameterize(separator: "_")
  end
end
