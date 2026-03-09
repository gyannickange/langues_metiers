# app/controllers/admin/trajectories_controller.rb
class Admin::TrajectoriesController < Admin::BaseController
  before_action :set_trajectory, only: [ :edit, :update, :destroy ]

  def index   = (@trajectories = Trajectory.includes(:career).order("careers.title")) && render
  def new     = (@trajectory = Trajectory.new(career_id: params[:career_id]); @careers = Career.behavioral.order(:title)) && render
  def edit    = (@careers = Career.behavioral.order(:title)) && render

  def create
    @trajectory = Trajectory.new(trajectory_params)
    @trajectory.save ? redirect_to(admin_trajectories_path, notice: "Trajectoire créée.") : ((@careers = Career.behavioral.order(:title)) && render(:new, status: :unprocessable_entity))
  end

  def update
    @trajectory.update(trajectory_params) ? redirect_to(admin_trajectories_path, notice: "Trajectoire mise à jour.") : ((@careers = Career.behavioral.order(:title)) && render(:edit, status: :unprocessable_entity))
  end

  def destroy
    @trajectory.destroy
    redirect_to admin_trajectories_path, notice: "Trajectoire supprimée."
  end

  private

  def set_trajectory = @trajectory = Trajectory.find(params[:id])
  def trajectory_params = params.require(:trajectory).permit(:career_id, :axe_1, :axe_2, :axe_3, :active)
end
