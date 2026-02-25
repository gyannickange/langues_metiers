# app/controllers/diagnostics_controller.rb
class DiagnosticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic, only: [:show, :questionnaire, :submit_bloc, :results, :pdf_status, :download_pdf]
  before_action :require_paid!,      only: [:questionnaire, :submit_bloc]
  before_action :require_completed!, only: [:results, :pdf_status, :download_pdf]

  def new
    @mobile_operators = MobileOperator.active.group_by(&:country_code)
    @default_country  = detect_country
  end

  def create
    @diagnostic = current_user.diagnostics.create!(payment_provider: payment_provider_param)

    case payment_provider_param
    when "stripe"  then handle_stripe_payment
    when "pawapay" then handle_pawapay_payment
    end
  end

  def show
    redirect_to case @diagnostic.status
    when "paid", "in_progress" then questionnaire_diagnostic_path(@diagnostic)
    when "completed" then results_diagnostic_path(@diagnostic)
    else new_diagnostic_path
    end
  end

  def questionnaire
    @current_bloc = current_bloc
    @questions    = Question.active.by_bloc(@current_bloc)
  end

  def submit_bloc
    bloc_number = params[:bloc].to_i

    Question.active.by_bloc(bloc_number).each do |question|
      value  = params.dig(:answers, question.id.to_s)
      next if value.blank?

      option = question.options.find { |o| o["value"] == value }
      next unless option

      @diagnostic.diagnostic_answers.find_or_create_by!(question: question) do |a|
        a.answer_value      = value
        a.profile_dimension = option["profile_slug"]
        a.points_awarded    = option["points"].to_i
      end
    end

    @diagnostic.update!(status: :in_progress) if @diagnostic.paid?

    if bloc_number >= 5
      Diagnostics::ScoringService.call(@diagnostic)
      redirect_to results_diagnostic_path(@diagnostic)
    else
      redirect_to questionnaire_diagnostic_path(@diagnostic, bloc: bloc_number + 1)
    end
  end

  def results
    @trajectory = @diagnostic.primary_profile&.active_trajectory

    if @diagnostic.provider_stripe? && !@diagnostic.pdf_generated?
      Diagnostics::GeneratePdfService.call(@diagnostic)
      @diagnostic.reload
    end
  end

  def pdf_status
    render json: { ready: @diagnostic.pdf_generated? }
  end

  def download_pdf
    if @diagnostic.pdf_report.attached?
      redirect_to rails_blob_path(@diagnostic.pdf_report, disposition: "attachment")
    else
      redirect_to results_diagnostic_path(@diagnostic), alert: t("diagnostics.pdf_not_ready", default: "PDF not ready yet")
    end
  end

  private

  def set_diagnostic
    @diagnostic = current_user.diagnostics.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def require_paid!
    unless @diagnostic.paid? || @diagnostic.in_progress? || @diagnostic.completed?
      redirect_to new_diagnostic_path
    end
  end

  def require_completed!
    redirect_to questionnaire_diagnostic_path(@diagnostic) unless @diagnostic.completed?
  end

  def payment_provider_param
    params[:payment_method].in?(%w[stripe pawapay]) ? params[:payment_method] : "stripe"
  end

  def handle_stripe_payment
    result = Payments::StripeCheckoutService.call(
      diagnostic:  @diagnostic,
      success_url: questionnaire_diagnostic_url(@diagnostic),
      cancel_url:  new_diagnostic_url
    )

    if result[:success]
      redirect_to result[:url], allow_other_host: true
    else
      @diagnostic.destroy
      redirect_to new_diagnostic_path, alert: result[:error]
    end
  end

  def handle_pawapay_payment
    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         params[:phone],
      operator_code: params[:operator_code]
    )

    if result[:success]
      redirect_to status_payment_path(@diagnostic.payment)
    else
      @diagnostic.destroy
      redirect_to new_diagnostic_path, alert: result[:error]
    end
  end

  def detect_country
    cookies[:country].presence || "CI"
  end

  def current_bloc
    (params[:bloc] || 1).to_i.clamp(1, 5)
  end
end
