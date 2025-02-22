class ProfilesController < ApplicationController
  before_action :require_user!

  def show
  end

  def edit
  end

  def update
    if Current.user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated!"
    else  
      render :show
    end
  end

  private 

  def profile_params
    params.require(:profile).permit(:username, :password, :password_confirmation)
  end

end
