# app/controllers/admin/diagnostics_controller.rb
class Admin::DiagnosticsController < Admin::BaseController
  def index
    @pagy, @diagnostics = pagy(
      Diagnostic.includes(:user, :primary_career, :payment).order(created_at: :desc)
    )
  end

  def show
    @diagnostic = Diagnostic.includes(:user, :primary_career, :complementary_career,
                                      { diagnostic_answers: :question }, :payment).find(params[:id])
    @questionnaire = @diagnostic.questionnaire || Questionnaire.find_by(active: true)
    @current_bloc = (params[:bloc] || 1).to_i
    @answers = @diagnostic.diagnostic_answers
                          .joins(:question)
                          .where(questions: { bloc: @current_bloc })
                          .order("questions.position")
  end
end
