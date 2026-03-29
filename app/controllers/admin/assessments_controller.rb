# app/controllers/admin/assessments_controller.rb
class Admin::AssessmentsController < Admin::BaseController
  before_action :set_assessment, only: [ :edit, :update, :destroy, :activate ]

  def index   = (@pagy, @assessments = pagy(Assessment.order(created_at: :desc))) && render
  def new     = (@assessment = Assessment.new) && render
  def edit    = render

  def create
    @assessment = Assessment.new(assessment_params)
    @assessment.save ? redirect_to(admin_assessments_path, notice: "Évaluation créée.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @assessment.update(assessment_params) ? redirect_to(admin_assessments_path, notice: "Évaluation mise à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @assessment.destroy
    redirect_to admin_assessments_path, notice: "Évaluation supprimée."
  end

  def activate
    @assessment.update!(active: true)
    redirect_to admin_assessments_path, notice: "L'évaluation est maintenant active."
  end

  private

  def set_assessment = @assessment = Assessment.find(params[:id])

  def assessment_params
    params.require(:assessment).permit(:title, :description, :active)
  end
end
