class UserSkillsController < ApplicationController
  before_action :authenticate_user!

  def create
    user_skill = current_user.user_skills.new(user_skill_params)
    if user_skill.save
      redirect_to edit_profile_path, notice: I18n.t("user_skills.created", default: "Skill added")
    else
      redirect_to edit_profile_path, alert: user_skill.errors.full_messages.to_sentence
    end
  end

  def destroy
    user_skill = current_user.user_skills.find(params[:id])
    user_skill.destroy
    redirect_to edit_profile_path, notice: I18n.t("user_skills.deleted", default: "Skill removed")
  end

  private

  def user_skill_params
    params.require(:user_skill).permit(:skill_id, :level)
  end
end
