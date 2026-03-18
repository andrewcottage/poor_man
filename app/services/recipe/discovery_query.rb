class Recipe::DiscoveryQuery
  SORT_OPTIONS = %w[newest rating popularity].freeze

  def initialize(scope:, params:)
    @scope = scope
    raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    @params = raw_params.symbolize_keys
  end

  def call
    scoped = scope.includes(:author, :category)
    scoped = apply_search(scoped)
    scoped = apply_filters(scoped)
    apply_sort(scoped)
  end

  private

  attr_reader :scope, :params

  def apply_search(current_scope)
    return current_scope unless params[:q].present?

    query = "%#{params[:q].to_s.strip}%"
    current_scope.left_joins(:tags).where(
      "recipes.title LIKE :query OR recipes.blurb LIKE :query OR tags.name LIKE :query",
      query: query
    ).distinct
  end

  def apply_filters(current_scope)
    filtered = current_scope

    if params[:difficulty].present?
      filtered = filtered.where(difficulty: params[:difficulty].to_i)
    end

    if params[:prep_time].present?
      filtered = filtered.where("prep_time <= ?", params[:prep_time].to_i)
    end

    if params[:cost].present?
      filtered = filtered.where("cost_cents <= ?", params[:cost].to_f * 100)
    end

    if dietary_tags.any?
      filtered = filtered.joins(:tags).where(tags: { name: dietary_tags }).group("recipes.id")
      filtered = filtered.having("COUNT(DISTINCT tags.id) >= ?", dietary_tags.size)
    end

    filtered
  end

  def apply_sort(current_scope)
    case params[:sort].presence_in(SORT_OPTIONS)
    when "rating"
      current_scope.left_joins(:ratings).group("recipes.id").order(Arel.sql("COALESCE(AVG(ratings.value), 0) DESC, recipes.created_at DESC"))
    when "popularity"
      current_scope.left_joins(:favorites, :ratings).group("recipes.id").order(Arel.sql("COUNT(DISTINCT favorites.id) DESC, COUNT(DISTINCT ratings.id) DESC, recipes.created_at DESC"))
    else
      current_scope.order(created_at: :desc)
    end
  end

  def dietary_tags
    Array(params[:dietary_tags]).reject(&:blank?)
  end
end
