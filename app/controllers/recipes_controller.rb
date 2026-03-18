class RecipesController < ApplicationController
  ITEMS = 12

  before_action :set_recipe, only: %i[ show edit update destroy cook print ]
  before_action :require_user!, only: %i[new create edit update destroy]
  before_action :require_recipe_editor!, only: %i[edit update destroy]

  skip_forgery_protection only: [:create]

  # GET /recipes or /recipes.json
  def index
    scoped_recipes = Recipe::DiscoveryQuery.new(scope: Recipe.approved, params: params).call
    @pagy, @recipes = pagy(scoped_recipes, items: ITEMS)
  end

  # GET /recipes/1 or /recipes/1.json
  def show
    @opengraph_title = @recipe.title
    @opengraph_description = @recipe.blurb
    @opengraph_image = @recipe.image.attached? ? url_for(@recipe.image) : nil
    @user_collections = Current.user&.collections&.order(:name)
    @related_recipes = @recipe.related_recipes
    @selected_servings = @recipe.normalized_servings(params[:servings])
    @scaled_ingredients = @recipe.scaled_ingredients(@selected_servings)
  end

  def cook
    @selected_servings = @recipe.normalized_servings(params[:servings])
    @scaled_ingredients = @recipe.scaled_ingredients(@selected_servings)
    @instruction_steps = @recipe.instruction_steps
  end

  def print
    @selected_servings = @recipe.normalized_servings(params[:servings])
    @scaled_ingredients = @recipe.scaled_ingredients(@selected_servings)
    @instruction_steps = @recipe.instruction_steps
    render layout: false
  end

  # GET /recipes/new
  def new
    if params[:generation_id].present?
      @generation = Recipe::Generation.find_by(id: params[:generation_id])
      @recipe = Recipe.from_generation(params[:generation_id]) || Recipe.new
    else
      @recipe = Recipe.new
    end
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes or /recipes.json
  def create
    unless Current.user.can_submit_recipe?
      redirect_to pricing_path, alert: "Free accounts can submit up to 5 recipes. Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} for unlimited submissions."
      return
    end

    @recipe = Current.user.recipes.new(recipe_attributes)
    prepare_generation_assets(@recipe)
    @recipe.mark_pending_review! unless Current.user.admin?

    respond_to do |format|
      if @recipe.save
        sync_recipe_ingredients(@recipe)
        format.html { redirect_to recipe_url(@recipe.slug), notice: created_notice_for(@recipe) }
        format.json { render :show, status: :created, location: @recipe }
      else
        reload_generation_for_form
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1 or /recipes/1.json
  def update
    @recipe.assign_attributes(recipe_attributes)
    @recipe.mark_pending_review! unless Current.user.admin?

    respond_to do |format|
      if @recipe.save
        sync_recipe_ingredients(@recipe)
        format.html { redirect_to recipe_url(@recipe.slug), notice: updated_notice_for(@recipe) }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/1 or /recipes/1.json
  def destroy
    @recipe.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_url, notice: "Recipe was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  def set_recipe
    @recipe = Recipe.visible_to(Current.user).find_by(slug: params[:slug]) || Recipe.visible_to(Current.user).find_by(id: params[:slug])
    raise ActiveRecord::RecordNotFound if @recipe.blank?
  end

  def require_recipe_editor!
    return if @recipe.current_user_editable?

    redirect_to recipe_path(@recipe.slug), alert: "You are not authorized to edit that recipe."
  end

  def recipe_params
    params.require(:recipe).permit(
      :title,
      :image,
      :slug,
      :instructions,
      :ingredient_list,
      :tag_names,
      :blurb,
      :difficulty,
      :servings,
      :prep_time,
      :category_id,
      :cost,
      :generation_id,
      images: [],
      ingredients: [ :quantity, :unit, :name, :notes ]
    )
  end

  def prepare_generation_assets(recipe)
    return if params[:recipe][:generation_id].blank?

    recipe.use_generated_images(params[:recipe][:generation_id])
  end

  def reload_generation_for_form
    return if params[:recipe][:generation_id].blank?

    @generation = Recipe::Generation.find_by(id: params[:recipe][:generation_id])
  end

  def created_notice_for(recipe)
    recipe.approved? ? "Recipe was successfully created." : "Recipe submitted for review."
  end

  def updated_notice_for(recipe)
    recipe.approved? ? "Recipe was successfully updated." : "Recipe resubmitted for review."
  end

  def recipe_attributes
    recipe_params.except(:generation_id, :ingredient_list, :ingredients)
  end

  def sync_recipe_ingredients(recipe)
    recipe.sync_recipe_ingredients!(
      ingredient_list: recipe_params[:ingredient_list],
      structured_ingredients: recipe_params[:ingredients]
    )
  end

end
