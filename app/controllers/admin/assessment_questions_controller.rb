# app/controllers/admin/assessment_questions_controller.rb
class Admin::AssessmentQuestionsController < Admin::BaseController
  before_action :set_assessment, only: [ :index, :new, :create ]
  before_action :set_assessment_question, only: [ :edit, :update, :destroy ]

  def index
    @current_bloc = (params[:bloc] || 1).to_i
    @status_filter = params[:status] || "active"

    @assessment_questions = @assessment ? @assessment.assessment_questions : AssessmentQuestion.all
    @assessment_questions = @assessment_questions.where(bloc: @current_bloc)

    if @status_filter == "active"
      @assessment_questions = @assessment_questions.active
    elsif @status_filter == "inactive"
      @assessment_questions = @assessment_questions.where(active: false)
    end

    @assessment_questions = @assessment_questions.order(:bloc, :position)
  end

  def new     = (@assessment_question = @assessment ? @assessment.assessment_questions.build : AssessmentQuestion.new) && render
  def edit    = render

  def create
    @assessment_question = @assessment ? @assessment.assessment_questions.build(assessment_question_params) : AssessmentQuestion.new(assessment_question_params)
    path = @assessment ? admin_assessment_assessment_questions_path(@assessment) : admin_assessment_questions_path
    @assessment_question.save ? redirect_to(path, notice: "Question d'évaluation créée.") : render(:new, status: :unprocessable_entity)
  end

  def update
    path = @assessment_question.assessment ? admin_assessment_assessment_questions_path(@assessment_question.assessment) : admin_assessment_questions_path
    @assessment_question.update(assessment_question_params) ? redirect_to(path, notice: "Question d'évaluation mise à jour.") : render(:edit, status: :unprocessable_entity)
  end

  def destroy
    path = @assessment_question.assessment ? admin_assessment_assessment_questions_path(@assessment_question.assessment) : admin_assessment_questions_path
    @assessment_question.destroy
    redirect_to path, notice: "Question d'évaluation supprimée."
  end

  def reorder
    params[:ordered_ids].each_with_index do |id, index|
      AssessmentQuestion.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  private

  def set_assessment = @assessment = Assessment.find_by(id: params[:assessment_id])
  def set_assessment_question = @assessment_question = AssessmentQuestion.find(params[:id])
  def assessment_question_params
    params.require(:assessment_question).permit(
      :bloc, :text, :kind, :scored, :position, :active, :assessment_id, :options_string,
      parsed_options: [ :text, :profile_slug ]
    )
  end
end

