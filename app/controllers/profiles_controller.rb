class ProfilesController < ApplicationController
  before_action :require_user!

  def show
    @recent_subscription = Current.user.subscriptions.recent_first.first
    @recent_credit_purchases = Current.user.credit_purchases.recent_first.limit(5)
  end

  def edit
  end

  def update
    if Current.user.update(profile_params)
      redirect_to profile_path(Current.user), notice: "Profile updated!"
    else
      render :show
    end
  end

  private 

  def profile_params
    params.require(:profile).permit(:avatar, :username, :password, :password_confirmation)
  end

end
  
