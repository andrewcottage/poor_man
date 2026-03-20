class Families::CookbooksController < ApplicationController
  before_action :require_user!
  before_action :set_family
  before_action :require_family_member!
  before_action :set_cookbook, only: %i[show edit update destroy]

  def show
  end

  def create
    @cookbook = @family.family_cookbooks.new(cookbook_params.merge(created_by: Current.user.id))

    if @cookbook.save
      redirect_to family_cookbook_path(@family, @cookbook), notice: "Cookbook created."
    else
      redirect_to family_path(@family), alert: @cookbook.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @cookbook.update(cookbook_params)
      redirect_to family_cookbook_path(@family, @cookbook), notice: "Cookbook updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @cookbook.destroy
    redirect_to family_path(@family), notice: "Cookbook deleted."
  end

  private

  def set_family
    @family = Family.find(params[:family_id])
  end

  def require_family_member!
    redirect_to families_path, alert: "You are not a member of this family." unless @family.member?(Current.user)
  end

  def set_cookbook
    @cookbook = @family.family_cookbooks.find(params[:id])
  end

  def cookbook_params
    params.require(:family_cookbook).permit(:name, :description)
  end
end
