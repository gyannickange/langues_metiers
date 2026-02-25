# app/controllers/admin/questions_controller.rb
class Admin::QuestionsController < Admin::BaseController
  before_action :set_question, only: [:edit, :update, :destroy]

  def index   = (@questions = Question.order(:bloc, :position)) && render
  def new     = (@question = Question.new) && render
  def edit    = render

  def create
    @question = Question.new(question_params)
    @question.save ? redirect_to(admin_questions_path, notice: "Question créée.") : render(:new, status: :unprocessable_entity)
  end

  def update
    @question.update(question_params) ? redirect_to(admin_questions_path, notice: "Question mise à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    @question.destroy
    redirect_to admin_questions_path, notice: "Question supprimée."
  end

  private

  def set_question = @question = Question.find(params[:id])
  def question_params
    params.require(:question).permit(:bloc, :text, :kind, :scored, :position, :active)
  end
end
