class Cooks::FollowsController < ApplicationController
  before_action :require_user!
  before_action :set_cook

  def create
    Current.user.active_follows.find_or_create_by!(followed: @cook)
    redirect_to cook_path(@cook.username), notice: "You are now following #{@cook.username}."
  end

  def destroy
    Current.user.active_follows.find_by(followed: @cook)&.destroy
    redirect_to cook_path(@cook.username), notice: "You unfollowed #{@cook.username}."
  end

  private

  def set_cook
    @cook = User.find_by!(username: params[:cook_username] || params[:username])
  end
end
