class FamiliesController < ApplicationController
  before_action :require_user!
  before_action :set_family, only: [:show, :edit, :update, :destroy]

  def index
    @families = Current.user.active_families.includes(:creator, :active_members)
  end

  def show
    redirect_to families_path, alert: 'You do not have access to this family' unless @family.member?(Current.user)
  end

  def new
    @family = Family.new
  end

  def create
    @family = Family.new(family_params)
    @family.creator = Current.user

    if @family.save
      redirect_to @family, notice: 'Family was successfully created.'
    else
      render :new
    end
  end

  def edit
    redirect_to families_path, alert: 'You are not authorized to edit this family' unless @family.can_manage?(Current.user)
  end

  def update
    redirect_to families_path, alert: 'You are not authorized to update this family' unless @family.can_manage?(Current.user)

    if @family.update(family_params)
      redirect_to @family, notice: 'Family was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    redirect_to families_path, alert: 'You are not authorized to delete this family' unless @family.can_manage?(Current.user)
    
    @family.destroy
    redirect_to families_path, notice: 'Family was successfully deleted.'
  end

  private

  def set_family
    @family = Family.find_by!(slug: params[:slug]) if params[:slug]
    @family ||= Family.find(params[:id])
  end

  def family_params
    params.require(:family).permit(:name, :description)
  end
end