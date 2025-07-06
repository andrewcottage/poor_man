class Recipes::GenerationsController < ApplicationController
  ITEMS = 12

  before_action :set_generation, only: %i[show edit update destroy]
  before_action :require_admin!, except: %i[index show]
  before_action :require_user!, only: %i[index show]

  # GET /recipes/generations
  def index
    if params[:q].present?
      @pagy, @generations = pagy(Recipe::Generation.where("prompt LIKE ?", "%#{params[:q]}%").order(created_at: :desc), items: ITEMS)
    else
      @pagy, @generations = pagy(Recipe::Generation.order(created_at: :desc), items: ITEMS)
    end
  end

  # GET /recipes/generations/1
  def show
  end

  # GET /recipes/generations/new
  def new
    @generation = Recipe::Generation.new
  end

  # GET /recipes/generations/1/edit
  def edit
  end
  
  # POST /recipes/generations
  def create
    @generation = Recipe::Generation.new(generation_params)
    @generation.user = Current.user

    respond_to do |format|
      if @generation.save
        format.html { redirect_to recipes_generation_url(@generation), notice: "Recipe Generation is in progress." }
        format.json { render :show, status: :created, location: @generation }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @generation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /recipes/generations/1
  def update
    respond_to do |format|
      if @generation.update(generation_params)
        format.html { redirect_to recipes_generation_url(@generation), notice: "Recipe Generation was successfully updated." }
        format.json { render :show, status: :ok, location: @generation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @generation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /recipes/generations/1
  def destroy
    @generation.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_generations_url, notice: "Recipe Generation was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_generation
    @generation = Recipe::Generation.find(params[:id])
  end

  def generation_params
    params.require(:recipe_generation).permit(:prompt)
  end
end