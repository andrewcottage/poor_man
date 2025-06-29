class Cookbooks::RecipesController < ApplicationController
  before_action :require_user!
  before_action :set_family_and_cookbook
  before_action :authorize_family_member!
  before_action :set_recipe, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @recipes = pagy(@cookbook.recipes.includes(:author, :category, image_attachment: :blob))
  end

  def show
  end

  def new
    @recipe = @cookbook.recipes.build
    @recipe.author = Current.user
    @categories = Category.all
  end

  def create
    @recipe = @cookbook.recipes.build(recipe_params)
    @recipe.author = Current.user

    if @recipe.save
      redirect_to [@family, @cookbook, @recipe], notice: 'Recipe was successfully added to the cookbook.'
    else
      @categories = Category.all
      render :new
    end
  end

  def edit
    unless can_edit_recipe?
      redirect_to [@family, @cookbook, @recipe], alert: 'You are not authorized to edit this recipe.'
      return
    end
    @categories = Category.all
  end

  def update
    unless can_edit_recipe?
      redirect_to [@family, @cookbook, @recipe], alert: 'You are not authorized to edit this recipe.'
      return
    end

    if @recipe.update(recipe_params)
      redirect_to [@family, @cookbook, @recipe], notice: 'Recipe was successfully updated.'
    else
      @categories = Category.all
      render :edit
    end
  end

  def destroy
    unless can_edit_recipe?
      redirect_to [@family, @cookbook], alert: 'You are not authorized to delete this recipe.'
      return
    end

    @recipe.destroy
    redirect_to [@family, @cookbook], notice: 'Recipe was successfully removed from the cookbook.'
  end

  private

  def set_family_and_cookbook
    @family = Family.find_by!(slug: params[:family_slug])
    @cookbook = @family.cookbooks.find_by!(slug: params[:cookbook_slug])
  end

  def set_recipe
    @recipe = @cookbook.recipes.find_by!(slug: params[:slug])
  end

  def authorize_family_member!
    redirect_to families_path, alert: 'You do not have access to this family cookbook.' unless @family.member?(Current.user)
  end

  def can_edit_recipe?
    @recipe.author == Current.user || @family.can_manage?(Current.user)
  end

  def recipe_params
    params.require(:recipe).permit(:title, :blurb, :instructions, :category_id, :image, :tag_names, :cost_cents, :difficulty, :prep_time, images: [])
  end
end