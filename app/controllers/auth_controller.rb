class AuthController < ApplicationController
  def callback
    user = User.from_omniauth(request.env['omniauth.auth'])

    if user.valid?
      session[:user_id] = user.id
      redirect_to root_path, notice: 'Logged in!'
    else
      session[:user_id] = nil
      redirect_to root_path, alert: 'Failed to login!'
    end
  end
end
