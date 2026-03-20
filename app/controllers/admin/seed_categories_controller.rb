class Admin::SeedCategoriesController < ApplicationController
  before_action :require_admin!
  before_action :set_category_seed_run, only: %i[show publish]

  def index
    @category_seed_runs = CategorySeedRun.includes(:published_category, :user).recent_first.limit(20)
  end

  def show
    @category_seed_runs = CategorySeedRun.includes(:published_category, :user).recent_first.limit(20)
  end

  def publish
    CategorySeedRunPublisher.new(@category_seed_run).call
    redirect_to admin_seed_category_path(@category_seed_run), notice: "Seed category published."
  rescue CategorySeedRunPublisher::PublishError => error
    redirect_to admin_seed_category_path(@category_seed_run), alert: error.message
  end

  private

  def set_category_seed_run
    @category_seed_run = CategorySeedRun.find(params[:id])
  end
end
