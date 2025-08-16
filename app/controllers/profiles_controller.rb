class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
    @skills = Skill.order(:name)
  end

  def update
    @user = current_user
    if @user.update(user_params)
      redirect_to profile_path, notice: I18n.t("profile.updated", default: "Profile updated")
    else
      @skills = Skill.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit()
  end
end
