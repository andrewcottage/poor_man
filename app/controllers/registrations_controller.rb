class RegistrationsController < ApplicationController
  def new
  end

  def create
    user = User.new(registration_params)

    if user.save
      session[:user_id] = user.id

      redirect_to root_path, notice: 'Logged in!'
    else
      flash.now[:alert] = 'Invalid email/password combination'
      render 'new'
    end

  end

  private

  def registration_params
    params.require(:registration).permit(:email, :password, :password_confirmation).merge(admin: false)
  end
end
