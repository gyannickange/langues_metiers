# app/controllers/admin/diagnostic_questions_controller.rb
class Admin::DiagnosticQuestionsController < Admin::BaseController
  before_action :set_assessment, only: [ :index, :new, :create ]
  before_action :set_question,   only: [ :edit, :update, :destroy ]

  def index
    @kind_filter = params[:kind].presence || "all"
    questions = @assessment ? @assessment.diagnostic_questions : DiagnosticQuestion.all
    questions = questions.where(kind: @kind_filter) unless @kind_filter == "all"
    @questions = questions.ordered
  end

  def new
    @question = @assessment ? @assessment.diagnostic_questions.build : DiagnosticQuestion.new
  end

  def edit; end

  def create
    @question = @assessment ? @assessment.diagnostic_questions.build(question_params) : DiagnosticQuestion.new(question_params)
    if @question.save
      redirect_to redirect_path, notice: "Question créée."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @question.update(question_params)
      redirect_to redirect_path, notice: "Question mise à jour."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @question.destroy
    redirect_to redirect_path, notice: "Question supprimée."
  end

  def reorder
    head :no_content
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id]) if params[:assessment_id]
  end

  def set_question
    @question   = DiagnosticQuestion.find(params[:id])
    @assessment = @question.assessment
  end

  def redirect_path
    @assessment ? admin_assessment_diagnostic_questions_path(@assessment) : admin_diagnostic_questions_path
  end

  def question_params
    params.require(:diagnostic_question).permit(
      :kind, :text, :disc_type, :competence_slug, :competence_label, :filiere_slug, :position, :active
    )
  end
end
