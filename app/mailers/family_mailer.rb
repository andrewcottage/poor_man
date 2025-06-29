class FamilyMailer < ApplicationMailer
  def invitation(family_membership)
    @family = family_membership.family
    @user = family_membership.user
    @inviter = @family.creator
    @invitation_token = family_membership.invitation_token
    @accept_url = accept_family_invitation_url(token: @invitation_token)
    @decline_url = decline_family_invitation_url(token: @invitation_token)
    
    mail(
      to: @user.email,
      subject: "You've been invited to join #{@family.name} family"
    )
  end
end