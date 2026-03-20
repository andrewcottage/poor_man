class Admin::SeedRecipesController < ApplicationController
  before_action :require_admin!
  before_action :set_seed_generation, only: %i[show publish]

  def index
    @generation = build_generation
    @seed_generations = seed_generations_scope.limit(20)
  end

  def show
    @seed_generations = seed_generations_scope.limit(20)
  end

  def create
    @generation = build_generation(seed_generation_params)

    if @generation.save
      notice = if @generation.auto_publish_recipe?
        "Seed generation started. The recipe will publish automatically when generation completes."
      else
        "Seed generation started."
      end

      redirect_to admin_seed_recipe_path(@generation), notice: notice
    else
      @seed_generations = seed_generations_scope.limit(20)
      render :index, status: :unprocessable_content
    end
  end

  def publish
    Recipe::GenerationPublisher.new(@generation).call
    redirect_to admin_seed_recipe_path(@generation), notice: "Seed recipe published."
  rescue Recipe::GenerationPublisher::PublishError => error
    redirect_to admin_seed_recipe_path(@generation), alert: error.message
  end

  private

  def build_generation(attributes = {})
    Current.user.recipe_generations.new({
      seed_tool: true,
      auto_publish_recipe: true,
      servings: 4
    }.merge(attributes))
  end

  def seed_generations_scope
    Recipe::Generation.seed_runs.includes(:published_recipe, :user).order(created_at: :desc)
  end

  def set_seed_generation
    @generation = Recipe::Generation.seed_runs.find(params[:id])
  end

  def seed_generation_params
    params.require(:recipe_generation).permit(
      :prompt,
      :dietary_preference,
      :skill_level,
      :ingredient_swaps,
      :avoid_ingredients,
      :customization_notes,
      :servings,
      :target_difficulty,
      :auto_publish_recipe
    )
  end
end
