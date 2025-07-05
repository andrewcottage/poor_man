class RecipesController < ApplicationController
  ITEMS = 12

  before_action :set_recipe, only: %i[ show edit update destroy generate_ai_image ]
  before_action :require_admin!, only: %i[ new create edit update destroy generate_ai_image ]
  before_action :require_user!, only: %i[ generate_ai_recipe ]
  
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
    @recipe = Recipe.new
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes or /recipes.json
  def create
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

  def generate_ai_recipe
    prompt = params[:prompt]
    
    if prompt.blank?
      render json: { error: "Prompt is required" }, status: :unprocessable_entity
      return
    end

         begin
       recipe = Recipe.generate_from_prompt(prompt, Current.user)
       
       render json: {
         title: recipe.title,
         blurb: recipe.blurb,
         instructions: recipe.instructions.try(:to_s) || recipe.instructions,
         tag_names: recipe.tag_names,
         difficulty: recipe.difficulty,
         prep_time: recipe.prep_time,
         cost: recipe.cost.to_s,
         category_id: recipe.category_id
       }
    rescue JSON::ParserError => e
      render json: { error: "Failed to parse AI response. Please try again." }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: "Failed to generate recipe. Please try again." }, status: :unprocessable_entity
         end
   end

   def generate_ai_image
     begin
       @recipe.generate_image_from_ai
       redirect_to edit_recipe_path(@recipe), notice: "AI image generated successfully!"
     rescue StandardError => e
       redirect_to edit_recipe_path(@recipe), alert: "Failed to generate AI image. Please try again."
     end
   end

   private
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.find_by(slug: params[:slug]) || Recipe.find_by(id: params[:slug]) 
    end

    # Only allow a list of trusted parameters through.
    def recipe_params
      params.require(:recipe).permit(:title, :image, :slug, :instructions, :tag_names, :blurb, :difficulty, :prep_time, :category_id, :cost, images: [])
    end
end
