# app/controllers/admin/profiles_controller.rb
class Admin::ProfilesController < Admin::BaseController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def index   = (@profiles = Profile.order(:name)) && render
  def show    = render
  def new     = (@profile = Profile.new) && render
  def edit    = render

  def create
    @profile = Profile.new(profile_params)
    @profile.save ? redirect_to(admin_profiles_path, notice: "Profil créé.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @profile.update(profile_params) ? redirect_to(admin_profiles_path, notice: "Profil mis à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @profile.destroy
    redirect_to admin_profiles_path, notice: "Profil supprimé."
  end

  private

  def set_profile   = @profile = Profile.find(params[:id])
  def profile_params
    params.require(:profile).permit(:name, :slug, :description, :first_action, :premium_pitch,
                                    key_skills: [])
  end
end
