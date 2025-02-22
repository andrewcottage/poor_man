class RecipesController < ApplicationController
  ITEMS = 12

  before_action :set_recipe, only: %i[ show edit update destroy ]
  before_action :require_admin!, only: %i[ new create edit update destroy ]
  
  skip_forgery_protection only: [:create]

  # GET /recipes or /recipes.json
  def index

    if params[:q]
      @pagy, @recipes = pagy(Recipe.where("title LIKE ?", "%#{params[:q]}%"), items: ITEMS)
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
    @recipe = Recipe.new
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes or /recipes.json
  def create

    # somtimes the image will be sent as a URL and not an active storage upload
    if recipe_params[:image].start_with?("http")
      image = Down.download(recipe_params[:image])
      recipe_params[:image] = { io: image, filename: File.basename(image.original_filename) }
    end

    @recipe = Current.user.recipes.new(recipe_params)
  
    respond_to do |format|
      if @recipe.save
        format.html { redirect_to recipe_url(@recipe.slug), notice: "Recipe was successfully created." }
        format.json { render :show, status: :created, location: @recipe }
      else
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
      params.require(:recipe).permit(:title, :image, :slug, :instructions, :tags, :blurb, :prep_time, :serves, :difficulty, :category_id)
    end
end
