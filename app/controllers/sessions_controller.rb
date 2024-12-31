class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)

    if user&.authenticate(params[:session][:password])
      session[:user_id] = user.id

      puts session[:return_to]
      puts "-----------------"

      redirect_to redirection_url, notice: 'Logged in!'
    else
      flash.now[:alert] = 'Invalid email/password combination'
      render 'new'
    end
  end


  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: 'Logged out!'
  end

  private 

  def redirection_url
    session_return_to = session[:return_to]
    session.delete(:return_to)
    session_return_to || root_path
  end
end