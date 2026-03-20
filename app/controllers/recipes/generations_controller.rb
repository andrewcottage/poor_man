class Recipes::GenerationsController < ApplicationController
  ITEMS = 12

  before_action :set_generation, only: %i[show edit update destroy regenerate_recipe regenerate_instructions regenerate_images]
  before_action :require_user!
  before_action :require_generation_owner!, only: %i[show edit update destroy regenerate_recipe regenerate_instructions regenerate_images]

  # GET /recipes/generations
  def index
    @remaining_generations = Current.user.remaining_recipe_generations
    @credit_packs = Billing::PlanCatalog::CREDIT_PACKS
    scope = Current.user.admin? ? Recipe::Generation.all : Current.user.recipe_generations

    if params[:q].present?
      @pagy, @generations = pagy(scope.where("prompt LIKE ?", "%#{params[:q]}%").order(created_at: :desc), items: ITEMS)
    else
      @pagy, @generations = pagy(scope.order(created_at: :desc), items: ITEMS)
    end
  end

  # GET /recipes/generations/1
  def show
  end

  # GET /recipes/generations/new
  def new
    @generation = Recipe::Generation.new
    @remaining_generations = Current.user.remaining_recipe_generations
    @credit_packs = Billing::PlanCatalog::CREDIT_PACKS
  end

  # GET /recipes/generations/1/edit
  def edit
  end
  
  # POST /recipes/generations
  def create
    @generation = Recipe::Generation.new(generation_params)
    @generation.user = Current.user
    @remaining_generations = Current.user.remaining_recipe_generations
    @credit_packs = Billing::PlanCatalog::CREDIT_PACKS

    unless Current.user.can_generate_recipe?
      @generation.errors.add(:base, generation_limit_message)
      render :new, status: :unprocessable_content
      return
    end

    respond_to do |format|
      if @generation.save
        Current.user.consume_recipe_generation!
        format.html { redirect_to recipes_generation_url(@generation), notice: "Recipe Generation is in progress." }
        format.json { render :show, status: :created, location: @generation }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @generation.errors, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @generation.errors, status: :unprocessable_content }
      end
    end
  end

  def regenerate_recipe
    if consume_generation_action!
      @generation.regenerate_recipe_data_later
      redirect_to recipes_generation_url(@generation), notice: "Recipe regeneration started."
    else
      redirect_to recipes_generation_url(@generation), alert: generation_limit_message
    end
  end

  def regenerate_instructions
    if consume_generation_action!
      @generation.regenerate_instructions_later
      redirect_to recipes_generation_url(@generation), notice: "Instruction regeneration started."
    else
      redirect_to recipes_generation_url(@generation), alert: generation_limit_message
    end
  end

  def regenerate_images
    if consume_generation_action!
      @generation.regenerate_images_later
      redirect_to recipes_generation_url(@generation), notice: "Image regeneration started."
    else
      redirect_to recipes_generation_url(@generation), alert: generation_limit_message
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

  def require_generation_owner!
    return if Current.user.admin? || @generation.user == Current.user

    redirect_to recipes_generations_path, alert: "You are not authorized to access that generation."
  end

  def generation_limit_message
    if Current.user.free?
      "Your free AI generation trial has been used. Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} or buy a credit pack for more generations."
    else
      "You have used all 15 #{Billing::PlanCatalog::PRO_DISPLAY_NAME} generations for this billing period. Buy a credit pack for more."
    end
  end

  def generation_params
    params.require(:recipe_generation).permit(
      :prompt,
      :dietary_preference,
      :skill_level,
      :avoid_ingredients,
      :ingredient_swaps,
      :customization_notes,
      :servings,
      :target_difficulty
    )
  end

  def consume_generation_action!
    Current.user.consume_recipe_generation!
  end
end
