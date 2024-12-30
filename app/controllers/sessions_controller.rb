class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)

    if user && user.authenticate(params[:session][:password])
      session[:user_id] = user.id

      redirection_location = params[:return_to] || root_path

      redirect_to redirection_location, notice: 'Logged in!'
    else
      flash.now[:alert] = 'Invalid email/password combination'
      render 'new'
    end
  end


  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: 'Logged out!'
  end
end