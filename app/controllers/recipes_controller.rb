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
      @generation = Recipe::Generation.find_by(id: params[:recipe][:generation_id])
      if @generation&.data&.present?
        copy_images_from_generation(@generation, @recipe)
      end
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



    def copy_images_from_generation(generation, recipe)
      # Copy main image if it exists
      if generation.image.attached?
        recipe.image.attach(
          io: StringIO.new(generation.image.blob.download),
          filename: generation.image.blob.filename,
          content_type: generation.image.blob.content_type
        )
      else
        # Create a placeholder image to satisfy validation if no generated image exists
        create_placeholder_image(recipe)
      end
      
      # Copy additional images
      generation.images.each do |image|
        recipe.images.attach(
          io: StringIO.new(image.blob.download),
          filename: image.blob.filename,
          content_type: image.blob.content_type
        )
      end
    end

    def create_placeholder_image(recipe)
      # Create a simple 1x1 pixel PNG placeholder
      placeholder_data = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1F\x15\xC4\x89\x00\x00\x00\rIDATx\x9Cc\xF8\x0F\x00\x00\x01\x00\x01\x00\x18\xDD\x8D\xB4\x00\x00\x00\x00IEND\xAEB`\x82"
      
      recipe.image.attach(
        io: StringIO.new(placeholder_data),
        filename: "placeholder.png",
        content_type: "image/png"
      )
    end


end
