# app/controllers/admin/mobile_operators_controller.rb
class Admin::MobileOperatorsController < Admin::BaseController
  before_action :set_operator, only: [:edit, :update, :destroy]

  def index   = (@operators = MobileOperator.order(:country_code, :name)) && render
  def new     = (@operator = MobileOperator.new) && render
  def edit    = render

  def create
    @operator = MobileOperator.new(operator_params)
    @operator.save ? redirect_to(admin_mobile_operators_path, notice: "Opérateur créé.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @operator.update(operator_params) ? redirect_to(admin_mobile_operators_path, notice: "Opérateur mis à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @operator.destroy
    redirect_to admin_mobile_operators_path, notice: "Opérateur supprimé."
  end

  private

  def set_operator = @operator = MobileOperator.find(params[:id])
  def operator_params = params.require(:mobile_operator).permit(:name, :code, :country_code, :logo_url, :active)
end
