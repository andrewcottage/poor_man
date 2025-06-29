class Families::MembershipsController < ApplicationController
  before_action :require_user!, except: [:accept, :decline]
  before_action :set_family, except: [:accept, :decline]
  before_action :set_membership_by_token, only: [:accept, :decline]
  before_action :authorize_family_manager!, except: [:accept, :decline]

  def index
    @active_memberships = @family.active_memberships.includes(:user)
    @pending_memberships = @family.pending_memberships.includes(:user)
  end

  def create
    user = User.find_by(email: params[:email])
    
    unless user
      redirect_to family_memberships_path(@family), alert: 'User not found with that email address.'
      return
    end

    if @family.member?(user)
      redirect_to family_memberships_path(@family), alert: 'User is already a member of this family.'
      return
    end

    if @family.pending_invitation_for?(user)
      redirect_to family_memberships_path(@family), alert: 'User already has a pending invitation.'
      return
    end

    membership = @family.family_memberships.build(user: user, status: :pending)
    
    if membership.save
      FamilyMailer.invitation(membership).deliver_now
      redirect_to family_memberships_path(@family), notice: 'Invitation sent successfully!'
    else
      redirect_to family_memberships_path(@family), alert: 'Failed to send invitation.'
    end
  end

  def destroy
    membership = @family.family_memberships.find(params[:id])
    user_name = membership.user.name || membership.user.username
    
    membership.destroy
    redirect_to family_memberships_path(@family), notice: "#{user_name} has been removed from the family."
  end

  def accept
    if @membership&.pending?
      @membership.accept!
      redirect_to families_path, notice: "You have joined #{@membership.family.name}!"
    else
      redirect_to root_path, alert: 'Invalid or expired invitation.'
    end
  end

  def decline
    if @membership&.pending?
      @membership.decline!
      redirect_to root_path, notice: 'You have declined the family invitation.'
    else
      redirect_to root_path, alert: 'Invalid or expired invitation.'
    end
  end

  private

  def set_family
    @family = Family.find_by!(slug: params[:family_slug]) if params[:family_slug]
    @family ||= Family.find(params[:family_id])
  end

  def set_membership_by_token
    @membership = FamilyMembership.find_by(invitation_token: params[:token])
  end

  def authorize_family_manager!
    redirect_to families_path, alert: 'You are not authorized to manage this family.' unless @family.can_manage?(Current.user)
  end
end