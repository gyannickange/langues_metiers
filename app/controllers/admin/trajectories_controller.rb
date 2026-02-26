# app/controllers/admin/trajectories_controller.rb
class Admin::TrajectoriesController < Admin::BaseController
  before_action :set_trajectory, only: [:edit, :update, :destroy]

  def index   = (@trajectories = Trajectory.includes(:profile).order("profiles.name")) && render
  def new     = (@trajectory = Trajectory.new(profile_id: params[:profile_id]); @profiles = Profile.order(:name)) && render
  def edit    = (@profiles = Profile.order(:name)) && render

  def create
    @trajectory = Trajectory.new(trajectory_params)
    @trajectory.save ? redirect_to(admin_trajectories_path, notice: "Trajectoire créée.") : ((@profiles = Profile.order(:name)) && render(:new, status: :unprocessable_entity))
  end

  def update
    @trajectory.update(trajectory_params) ? redirect_to(admin_trajectories_path, notice: "Trajectoire mise à jour.") : ((@profiles = Profile.order(:name)) && render(:edit, status: :unprocessable_entity))
  end

  def destroy
    @trajectory.destroy
    redirect_to admin_trajectories_path, notice: "Trajectoire supprimée."
  end

  private

  def set_trajectory = @trajectory = Trajectory.find(params[:id])
  def trajectory_params = params.require(:trajectory).permit(:profile_id, :axe_1, :axe_2, :axe_3, :active)
end
