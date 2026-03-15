class Api::RecipesController < Api::BaseController
  before_action :set_recipe, only: :update
  before_action :require_recipe_owner!, only: :update

  def create
    @recipe = Current.user.recipes.new(recipe_attributes)
    assign_category(@recipe)
    return render_unprocessable(@recipe) if category_lookup_failed?

    if @recipe.save
      render :show, status: :created
    else
      render_unprocessable(@recipe)
    end
  end

  def update
    @recipe.assign_attributes(recipe_attributes)
    assign_category(@recipe) if category_lookup_param.present?
    return render_unprocessable(@recipe) if category_lookup_failed?

    if @recipe.save
      render :show, status: :ok
    else
      render_unprocessable(@recipe)
    end
  end

  private

  def set_recipe
    @recipe = Recipe.find_by!(slug: params[:slug])
  end

  def require_recipe_owner!
    render_forbidden unless @recipe.author == Current.user
  end

  def recipe_attributes
    recipe_params.except(:category_slug)
  end

  def assign_category(recipe)
    return if category_lookup_param.blank?

    recipe.category = if recipe_params[:category_id].present?
      Category.find(recipe_params[:category_id])
    else
      Category.find_by!(slug: recipe_params[:category_slug])
    end
  rescue ActiveRecord::RecordNotFound
    @category_lookup_failed = true
    recipe.errors.add(:category, "must exist")
  end

  def category_lookup_param
    recipe_params[:category_slug].presence || recipe_params[:category_id].presence
  end

  def category_lookup_failed?
    @category_lookup_failed == true
  end

  def recipe_params
    params.require(:recipe).permit(
      :title,
      :image,
      :slug,
      :instructions,
      :tag_names,
      :blurb,
      :difficulty,
      :prep_time,
      :category_id,
      :category_slug,
      :cost,
      images: []
    )
  end
end
