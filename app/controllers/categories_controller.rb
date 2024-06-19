class CategoriesController < ApplicationController
  ITEMS = 12

  before_action :set_category, only: %i[ show edit update destroy ]
  before_action :require_admin!, only: %i[ new create edit update destroy ]

# GET /categories or /categories.json
  def index
    if params[:q].present?
      @pagy, @categories = pagy(Category.where("title LIKE ?", "%#{params[:q]}%"), items: ITEMS)
    else
      @pagy, @categories = pagy(Category.all, items: ITEMS)
    end
  end

  # GET /categories/1 or /categories/1.json
  def show
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # GET /categories/1/edit
  def edit
  end

  # POST /categories or /categories.json
  def create
    @category = Category.new(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to category_url(@category.slug), notice: "Category was successfully created." }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categories/1 or /categories/1.json
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to category_url(@category.slug), notice: "Category was successfully updated." }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1 or /categories/1.json
  def destroy
    @category.destroy!

    respond_to do |format|
      format.html { redirect_to categories_url, notice: "Category was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find_by!(slug: params[:slug])
    end

    # Only allow a list of trusted parameters through.
    def category_params
      params.require(:category).permit(:name, :slug, :description, :recipies_count, :image)
    end
end
