# app/controllers/admin/diagnostic_questions_controller.rb
class Admin::DiagnosticQuestionsController < Admin::BaseController
  before_action :set_assessment
  before_action :set_question, only: [ :update, :destroy, :history ]

  def index
    @kind_filter = params[:kind].presence || "all"
    @questions = load_questions
  end

  def create
    @kind_filter = params[:kind].presence || "all"
    @question = @assessment.diagnostic_questions.build(question_params)
    @question.position = next_position_for(@question.kind)

    if @question.save
      if inline_edit_request?
        render turbo_stream: turbo_stream.replace("questions_tbody", partial: "questions_table_body",
          locals: { assessment: @assessment, questions: load_questions, kind_filter: @kind_filter })
      else
        redirect_to redirect_path, notice: "Question créée."
      end
    elsif inline_edit_request?
      render turbo_stream: turbo_stream.replace(helpers.dom_id(@question), partial: "question_form_row",
        locals: { question: @question, assessment: @assessment, kind_filter: @kind_filter, mode: :create,
                  edit_errors: @question.errors, hidden: false, new_row: true }),
        status: :unprocessable_content
    else
      head :unprocessable_content
    end
  end

  def update
    @kind_filter = params[:kind].presence || "all"
    full_row_edit = question_params.key?(:kind)
    sortable_enabled = @kind_filter != "all"

    if @question.update(question_params)
      if inline_edit_request? && full_row_edit
        render turbo_stream: turbo_stream.replace("questions_tbody", partial: "questions_table_body",
          locals: { assessment: @assessment, questions: load_questions, kind_filter: @kind_filter })
      elsif inline_edit_request?
        render turbo_stream: turbo_stream.replace(@question, partial: "question_row",
          locals: { q: @question, assessment: @assessment, kind_filter: @kind_filter, sortable_enabled: sortable_enabled })
      else
        redirect_to redirect_path, notice: "Question mise à jour.", status: :see_other
      end
    elsif inline_edit_request? && full_row_edit
      render turbo_stream: turbo_stream.replace("#{helpers.dom_id(@question)}_edit", partial: "question_form_row",
        locals: { question: @question, assessment: @assessment, kind_filter: @kind_filter, mode: :edit,
                  edit_errors: @question.errors, hidden: false }),
        status: :unprocessable_content
    elsif inline_edit_request?
      render turbo_stream: turbo_stream.replace(@question, partial: "question_row",
        locals: { q: @question, assessment: @assessment, kind_filter: @kind_filter, sortable_enabled: sortable_enabled, inline_errors: @question.errors }),
        status: :unprocessable_content
    else
      head :unprocessable_content
    end
  end

  def destroy
    @question.destroy
    redirect_to redirect_path, notice: "Question supprimée.", status: :see_other
  end

  def history
    render partial: "history_frame", locals: { question: @question }
  end

  def reorder
    kind = params[:kind].presence
    ids  = Array(params[:ordered_ids]).reject(&:blank?)
    return head :unprocessable_content if kind.blank?

    questions_by_id = @assessment.diagnostic_questions.where(kind: kind).index_by { |q| q.id.to_s }

    return head :unprocessable_content if ids.sort != questions_by_id.keys.sort

    ActiveRecord::Base.transaction do
      ids.each_with_index { |id, index| questions_by_id[id].update!(position: index + 1) }
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

  def load_questions
    if @kind_filter == "all"
      @assessment.diagnostic_questions.order(Arel.sql("array_position(ARRAY['interest','disc','skill'], kind)"), :position)
    else
      @assessment.diagnostic_questions.where(kind: @kind_filter).ordered
    end
  end

  def redirect_path
    admin_assessment_diagnostic_questions_path(@assessment)
  end

  def next_position_for(kind)
    @assessment.diagnostic_questions.where(kind: kind).maximum(:position).to_i + 1
  end

  # :position is intentionally omitted — it's drag-only, assigned by `create`
  # (next_position_for) or the `reorder` action, never by direct params.
  def question_params
    params.require(:diagnostic_question).permit(
      :kind, :text, :disc_type, :skill_slug, :skill_label, :academic_field_slug, :active
    )
  end

  def inline_edit_request?
    request.headers["X-Inline-Edit"].present?
  end
end
