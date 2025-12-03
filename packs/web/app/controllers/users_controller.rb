class UsersController < ApplicationController
  before_action :require_admin!

  def index
    @users = User.order(:name)
  end

  def show
    @user = User.find(params[:id])
    @tokens = @user.api_tokens.order(created_at: :desc)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    attributes = user_params
    attributes.delete(:password) if attributes[:password].blank?

    if own_role_change?(attributes) || own_deactivation?(attributes)
      @user.errors.add(:base, own_role_change?(attributes) ? "you cannot change your own role" : "you cannot deactivate yourself")
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(attributes)
      redirect_to @user, notice: "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    if user == current_user
      return redirect_to user, alert: "You cannot delete your own account."
    end

    user.destroy!
    redirect_to users_path, notice: "Account removed."
  rescue Dispatch::ValidationFailed => error
    redirect_to user, alert: error.message.upcase_first
  end

  private

  def user_params
    params.expect(user: [ :email, :name, :role, :is_active, :password ])
  end

  def own_role_change?(attributes)
    @user == current_user && attributes.key?(:role) && attributes[:role] != @user.role
  end

  def own_deactivation?(attributes)
    @user == current_user && attributes.key?(:is_active) && attributes[:is_active] != "1"
  end
end
