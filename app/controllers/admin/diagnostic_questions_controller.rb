# app/controllers/admin/diagnostic_questions_controller.rb
class Admin::DiagnosticQuestionsController < Admin::BaseController
  before_action :set_assessment
  before_action :set_question, only: [ :edit, :update, :destroy ]

  def index
    @kind_filter = params[:kind].presence || "all"
    questions = @assessment.diagnostic_questions
    questions = questions.where(kind: @kind_filter) unless @kind_filter == "all"
    @questions = questions.ordered
  end

  def new
    kind = params[:kind].presence || "interest"
    @question = @assessment.diagnostic_questions.build(kind: kind, position: next_position_for(kind))
  end

  def edit; end

  def create
    @question = @assessment.diagnostic_questions.build(question_params)
    if @question.save
      redirect_to redirect_path, notice: "Question créée."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @question.update(question_params)
      redirect_to redirect_path, notice: "Question mise à jour.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @question.destroy
    redirect_to redirect_path, notice: "Question supprimée.", status: :see_other
  end

  def reorder
    kind = params[:kind].presence
    ids  = Array(params[:ordered_ids]).reject(&:blank?)
    scope = @assessment.diagnostic_questions.where(kind: kind)

    if kind.blank? || ids.sort != scope.pluck(:id).map(&:to_s).sort
      return head :unprocessable_content
    end

    ActiveRecord::Base.transaction do
      ids.each_with_index { |id, index| scope.find(id).update!(position: index + 1) }
    end

    head :no_content
  end

  private

  def set_assessment
    @assessment = Assessment.find(params[:assessment_id])
  end

  def set_question
    @question = @assessment.diagnostic_questions.find(params[:id])
  end

  def redirect_path
    admin_assessment_diagnostic_questions_path(@assessment)
  end

  def next_position_for(kind)
    @assessment.diagnostic_questions.where(kind: kind).maximum(:position).to_i + 1
  end

  def question_params
    params.require(:diagnostic_question).permit(
      :kind, :text, :disc_type, :skill_slug, :skill_label, :academic_field_slug, :position, :active
    )
  end
end
