# app/controllers/admin/questionnaires_controller.rb
class Admin::QuestionnairesController < Admin::BaseController
  before_action :set_questionnaire, only: [ :edit, :update, :destroy, :activate ]

  def index   = (@pagy, @questionnaires = pagy(Questionnaire.order(created_at: :desc))) && render
  def new     = (@questionnaire = Questionnaire.new) && render
  def edit    = render

  def create
    @questionnaire = Questionnaire.new(questionnaire_params)
    @questionnaire.save ? redirect_to(admin_questionnaires_path, notice: "Questionnaire créé.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @questionnaire.update(questionnaire_params) ? redirect_to(admin_questionnaires_path, notice: "Questionnaire mis à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @questionnaire.destroy
    redirect_to admin_questionnaires_path, notice: "Questionnaire supprimé."
  end

  def activate
    @questionnaire.update!(active: true)
    redirect_to admin_questionnaires_path, notice: "Le questionnaire est maintenant actif."
  end

  private

  def set_questionnaire = @questionnaire = Questionnaire.find(params[:id])
  
  def questionnaire_params
    params.require(:questionnaire).permit(:title, :description, :active)
  end
end
