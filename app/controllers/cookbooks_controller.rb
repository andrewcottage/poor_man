class CookbooksController < ApplicationController
  before_action :require_user!
  before_action :set_family
  before_action :set_cookbook, only: [:show, :edit, :update, :destroy]
  before_action :authorize_family_member!, only: [:show]
  before_action :authorize_family_manager!, only: [:new, :create, :edit, :update, :destroy]

  def index
    @cookbooks = @family.cookbooks.includes(:recipes)
  end

  def show
    @pagy, @recipes = pagy(@cookbook.recipes.includes(:author, :category, image_attachment: :blob))
  end

  def new
    @cookbook = @family.cookbooks.build
  end

  def create
    @cookbook = @family.cookbooks.build(cookbook_params)

    if @cookbook.save
      redirect_to [@family, @cookbook], notice: 'Cookbook was successfully created.'
    else
      render :new
    end
  end

  def edit
    redirect_to [@family, @cookbook], alert: 'Cannot edit the default cookbook name' if @cookbook.is_default? && cookbook_params[:name] != @cookbook.name
  end

  def update
    # Prevent editing default cookbook's name
    if @cookbook.is_default? && cookbook_params[:name] != @cookbook.name
      redirect_to [@family, @cookbook], alert: 'Cannot change the name of the default cookbook'
      return
    end

    if @cookbook.update(cookbook_params)
      redirect_to [@family, @cookbook], notice: 'Cookbook was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if @cookbook.is_default?
      redirect_to [@family, @cookbook], alert: 'Cannot delete the default cookbook'
      return
    end

    @cookbook.destroy
    redirect_to family_cookbooks_path(@family), notice: 'Cookbook was successfully deleted.'
  end

  private

  def set_family
    @family = Family.find_by!(slug: params[:family_slug]) if params[:family_slug]
    @family ||= Family.find(params[:family_id])
  end

  def set_cookbook
    @cookbook = @family.cookbooks.find_by!(slug: params[:slug]) if params[:slug]
    @cookbook ||= @family.cookbooks.find(params[:id])
  end

  def authorize_family_member!
    redirect_to families_path, alert: 'You do not have access to this family cookbook.' unless @family.member?(Current.user)
  end

  def authorize_family_manager!
    redirect_to families_path, alert: 'You are not authorized to manage cookbooks.' unless @family.can_manage?(Current.user)
  end

  def cookbook_params
    params.require(:cookbook).permit(:name, :description)
  end
end