# app/controllers/admin/diagnostics_controller.rb
class Admin::DiagnosticsController < Admin::BaseController
  def index
    @status_filter = params[:status] || "completed"

    scope = Diagnostic.includes(:user, :primary_career, :payment).order(created_at: :desc)
    scope = scope.where(status: @status_filter) if @status_filter != "all"

    @pagy, @diagnostics = pagy(scope)
  end

  def show
    @diagnostic = Diagnostic.includes(:user, :primary_career, :complementary_career,
                                      { diagnostic_answers: :diagnostic_question }, :payment).find(params[:id])
    @assessment = @diagnostic.assessment || Assessment.find_by(active: true)
    @answers = @diagnostic.diagnostic_answers
                          .joins(:diagnostic_question)
                          .order("diagnostic_questions.position")
    @attribution = Diagnostics::AnswerAttributionPresenter.new(@diagnostic)
  end
end
