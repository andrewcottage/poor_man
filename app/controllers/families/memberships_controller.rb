class Families::MembershipsController < ApplicationController
  before_action :require_user!
  before_action :set_family
  before_action :require_family_admin!
  before_action :set_membership, only: %i[update destroy]

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user.nil?
      redirect_to family_path(@family), alert: "No user found with that email."
      return
    end

    if @family.member?(user)
      redirect_to family_path(@family), alert: "#{user.email} is already a member."
      return
    end

    @family.family_memberships.create!(user: user, role: :member)
    redirect_to family_path(@family), notice: "#{user.email} has been added to the family."
  end

  def update
    if @membership.owner?
      redirect_to family_path(@family), alert: "Cannot change the owner's role."
      return
    end

    @membership.update!(role: params[:role])
    redirect_to family_path(@family), notice: "Role updated."
  end

  def destroy
    if @membership.owner?
      redirect_to family_path(@family), alert: "The owner cannot be removed."
      return
    end

    @membership.destroy
    if @membership.user == Current.user
      redirect_to families_path, notice: "You have left the family."
    else
      redirect_to family_path(@family), notice: "Member removed."
    end
  end

  private

  def set_family
    @family = Family.find(params[:family_id])
  end

  def require_family_admin!
    # Members can remove themselves
    if action_name == "destroy" && params[:id].present?
      membership = @family.family_memberships.find(params[:id])
      return if membership.user == Current.user
    end

    redirect_to family_path(@family), alert: "You don't have permission to do that." unless @family.admin_or_owner?(Current.user)
  end

  def set_membership
    @membership = @family.family_memberships.find(params[:id])
  end
end
