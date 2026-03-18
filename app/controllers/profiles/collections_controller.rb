class Profiles::CollectionsController < ApplicationController
  before_action :require_user!
  before_action :set_collection, only: %i[show edit update destroy]

  def index
    @collections = Current.user.collections.includes(:recipes).descending
    @collection = Current.user.collections.new
  end

  def show
  end

  def new
    @collection = Current.user.collections.new
  end

  def create
    unless Current.user.can_create_collection?
      redirect_to pricing_path, alert: "Free accounts can create 1 collection. Upgrade to #{Billing::PlanCatalog::PRO_DISPLAY_NAME} for unlimited cookbooks."
      return
    end

    @collection = Current.user.collections.new(collection_params)

    if @collection.save
      redirect_to profiles_collection_path(@collection), notice: "Collection created."
    else
      @collections = Current.user.collections.includes(:recipes).descending
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to profiles_collection_path(@collection), notice: "Collection updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to profiles_collections_path, notice: "Collection deleted."
  end

  private

  def set_collection
    @collection = Current.user.collections.find(params[:id])
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end
