class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user.present? && user.provider.blank?
      token = user.generate_token_for(:password_reset)
      UserMailer.password_reset(user, token).deliver_later
    end

    render :create
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])

    redirect_to new_password_reset_url, alert: "That reset link is invalid or has expired." unless @user
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_url, alert: "That reset link is invalid or has expired."
      return
    end

    if params[:password].blank?
      @user.errors.add(:password, :blank)
      render :edit, status: :unprocessable_content
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      reset_session
      session[:user_id] = @user.id
      redirect_to root_url, notice: "Your password has been reset."
    else
      render :edit, status: :unprocessable_content
    end
  end
end
