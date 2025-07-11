class RecipesController < ApplicationController
  ITEMS = 12

  before_action :set_recipe, only: %i[ show edit update destroy ]
  before_action :require_admin!, only: %i[ new create edit update destroy ]
  
  skip_forgery_protection only: [:create]

  # GET /recipes or /recipes.json
  def index

    if params[:q]
      @pagy, @recipes = pagy(Recipe.left_joins(:tags).where("recipes.title LIKE :q OR tags.name LIKE :q", q: "%#{params[:q]}%").distinct.descending, items: ITEMS)
    else
      @pagy, @recipes = pagy(Recipe.descending, items: ITEMS)
    end
  end

  # GET /recipes/1 or /recipes/1.json
  def show
    @opengraph_title = @recipe.title
    @opengraph_description = @recipe.blurb
    @opengraph_image = @recipe.image.attached? ? url_for(@recipe.image) : nil
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
    @recipe = Current.user.recipes.new(recipe_params.except(:generation_id))
    
    # Handle image copying from generation if generation_id is present
    if params[:recipe][:generation_id].present?
      @recipe.use_generated_images(params[:recipe][:generation_id])
    end
  
    respond_to do |format|
      if @recipe.save
        format.html { redirect_to recipe_url(@recipe.slug), notice: "Recipe was successfully created." }
        format.json { render :show, status: :created, location: @recipe }
      else
        # If saving fails and we came from a generation, reload the generation for the form
        if params[:recipe][:generation_id].present?
          @generation = Recipe::Generation.find_by(id: params[:recipe][:generation_id])
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/1 or /recipes/1.json
  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to recipe_url(@recipe.slug), notice: "Recipe was successfully updated." }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.find_by(slug: params[:slug]) || Recipe.find_by(id: params[:slug]) 
    end

    # Only allow a list of trusted parameters through.
    def recipe_params
      params.require(:recipe).permit(:title, :image, :slug, :instructions, :tag_names, :blurb, :difficulty, :prep_time, :category_id, :cost, :generation_id, images: [])
    end

end
