class Profiles::FamiliesController < ApplicationController
  before_action :require_user!

  def index
    @active_families = Current.user.active_families.includes(:creator, :active_members, :cookbooks)
    @pending_invitations = Current.user.pending_family_memberships.includes(:family)
    @created_families = Current.user.created_families.includes(:active_members, :cookbooks)
  end
end