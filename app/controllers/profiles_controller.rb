class ProfilesController < ApplicationController
  before_action :load_activities
  before_action :authenticate_user!
  rescue_from ActiveRecord::RecordNotFound, with: :invalid_user

  def show
    @user = User.friendly.find(params[:id])
    @friendship = current_user.friendships.where(friend_id: @user).first
    @statuses = @user.statuses.order('id desc')
  end

  def index
    @users = User.search(params[:search]).order('slug asc')
  end

  private

  def load_activities
    @activities = PublicActivity::Activity.order('created_at DESC').limit(15).includes(:owner).includes(:recipient).includes(:trackable)
  end

  def invalid_user
    redirect_to profiles_url, error: "User not found"
  end

end
