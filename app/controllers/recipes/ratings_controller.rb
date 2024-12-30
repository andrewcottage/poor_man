class Recipes::RatingsController < ApplicationController
  before_action :set_recipe
  before_action :require_user!
  before_action :only_allow_one_rating_per_user, only: [:new]  


  def new
    @rating = @recipe.ratings.new
  end

  def edit
    @rating = @recipe.current_user_rating
  end

  def create
    @rating = @recipe.ratings.new(rating_params)
    @rating.user = Current.user
  
    respond_to do |format|
      if @rating.save
        format.html { redirect_to recipe_url(@recipe.slug), notice: "Recipe was successfully created." }
        format.json { render :show, status: :created, location: @rating }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rating.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @rating = @recipe.current_user_rating
    
    respond_to do |format|
      if @rating.update(rating_params)
        format.html { redirect_to recipe_url(@recipe.slug), notice: "Recipe was successfully updated." }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @recipe.errors, status: :unprocessable_entity }
      end
    end
  end


  def destroy
    @recipe.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_url, notice: "Recipe was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

    def set_recipe
      @recipe = Recipe.find_by(slug: params[:recipe_slug]) || Recipe.find_by(id: params[:recipe_slug]) 
    end

    def rating_params
      params.require(:rating).permit(:value, :comment, :title)
    end

    def only_allow_one_rating_per_user
      redirect_to recipe_url(@recipe.slug), notice: "Rating already exists." if @recipe.current_user_rating
    end
end
