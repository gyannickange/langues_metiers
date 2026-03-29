# app/controllers/admin/questions_controller.rb
class Admin::QuestionsController < Admin::BaseController
  before_action :set_questionnaire, only: [ :index, :new, :create ]
  before_action :set_question, only: [ :edit, :update, :destroy ]

  def index
    @current_bloc = (params[:bloc] || 1).to_i
    @status_filter = params[:status] || "active"

    @questions = @questionnaire ? @questionnaire.questions : Question.all
    @questions = @questions.where(bloc: @current_bloc)

    if @status_filter == "active"
      @questions = @questions.active
    elsif @status_filter == "inactive"
      @questions = @questions.where(active: false)
    end

    @questions = @questions.order(:bloc, :position)
  end
  def new     = (@question = @questionnaire ? @questionnaire.questions.build : Question.new) && render
  def edit    = render

  def create
    @question = @questionnaire ? @questionnaire.questions.build(question_params) : Question.new(question_params)
    path = @questionnaire ? admin_questionnaire_questions_path(@questionnaire) : admin_questions_path
    @question.save ? redirect_to(path, notice: "Question créée.") : render(:new, status: :unprocessable_entity)
  end

  def update
    path = @question.questionnaire ? admin_questionnaire_questions_path(@question.questionnaire) : admin_questions_path
    @question.update(question_params) ? redirect_to(path, notice: "Question mise à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    path = @question.questionnaire ? admin_questionnaire_questions_path(@question.questionnaire) : admin_questions_path
    @question.destroy
    redirect_to path, notice: "Question supprimée."
  end

  def reorder
    params[:ordered_ids].each_with_index do |id, index|
      Question.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  private

  def set_questionnaire = @questionnaire = Questionnaire.find_by(id: params[:questionnaire_id])
  def set_question = @question = Question.find(params[:id])
  def question_params
    params.require(:question).permit(
      :bloc, :text, :kind, :scored, :position, :active, :questionnaire_id, :options_string,
      parsed_options: [ :text, :profile_slug ]
    )
  end
end
