class FamiliesController < ApplicationController
  before_action :require_user!
  before_action :set_family, only: %i[show edit update destroy]
  before_action :require_family_member!, only: %i[show]
  before_action :require_family_admin!, only: %i[edit update destroy]

  def index
    @families = Current.user.families.includes(:members, :family_cookbooks)
    @family = Family.new
  end

  def show
    @cookbooks = @family.family_cookbooks.includes(:recipes)
    @membership = @family.family_memberships.find_by(user: Current.user)
  end

  def create
    @family = Family.new(family_params.merge(created_by: Current.user.id))

    if @family.save
      @family.family_memberships.create!(user: Current.user, role: :owner)
      redirect_to family_path(@family), notice: "Family created."
    else
      @families = Current.user.families.includes(:members, :family_cookbooks)
      render :index, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @family.update(family_params)
      redirect_to family_path(@family), notice: "Family updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @family.destroy
    redirect_to families_path, notice: "Family deleted."
  end

  private

  def set_family
    @family = Family.find(params[:id])
  end

  def require_family_member!
    redirect_to families_path, alert: "You are not a member of this family." unless @family.member?(Current.user)
  end

  def require_family_admin!
    redirect_to families_path, alert: "You don't have permission to do that." unless @family.admin_or_owner?(Current.user)
  end

  def family_params
    params.require(:family).permit(:name)
  end
end
