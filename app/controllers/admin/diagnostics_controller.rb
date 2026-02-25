# app/controllers/admin/diagnostics_controller.rb
class Admin::DiagnosticsController < Admin::BaseController
  def index
    @pagy, @diagnostics = pagy(
      Diagnostic.includes(:user, :primary_profile, :payment).order(created_at: :desc)
    )
  end

  def show
    @diagnostic = Diagnostic.includes(:user, :primary_profile, :complementary_profile,
                                      :diagnostic_answers, :payment).find(params[:id])
  end
end
