# app/controllers/diagnostics_controller.rb
class DiagnosticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic, only: [ :show, :questionnaire, :submit_bloc, :pay, :process_payment, :results, :pdf_status, :download_pdf ]
  before_action :require_paid!,      only: [ :results, :pdf_status, :download_pdf ]

  def new
    unless current_user.admin?
      render "coming_soon"
      return
    end

    questionnaire = Questionnaire.find_by(active: true) || Questionnaire.first
    unless questionnaire
      redirect_to root_path, alert: "Aucun diagnostic disponible pour le moment."
      return
    end

    @diagnostic = current_user.diagnostics.create!(status: :in_progress, questionnaire: questionnaire)
    redirect_to questionnaire_diagnostic_path(@diagnostic)
  end

  def pay
    @mobile_operators = MobileOperator.active.group_by(&:country_code)
    @default_country  = detect_country
  end

  def process_payment
    @diagnostic.update!(payment_provider: payment_provider_param)

    if !Rails.env.production?
      # Simulation de paiement en local (0 XOF)
      @diagnostic.update!(status: :paid)
      @diagnostic.create_payment!(
        user: @diagnostic.user,
        provider: payment_provider_param,
        provider_payment_id: "dev_payment_#{SecureRandom.hex(4)}",
        status: :confirmed
      )
      redirect_to results_diagnostic_path(@diagnostic), notice: "Paiement simulé avec succès (0 XOF)"
      return
    end

    case payment_provider_param
    when "stripe"  then handle_stripe_payment
    when "pawapay" then handle_pawapay_payment
    end
  end

  def show
    redirect_to case @diagnostic.status
    when "in_progress" then questionnaire_diagnostic_path(@diagnostic)
    when "pending_payment" then pay_diagnostic_path(@diagnostic)
    when "paid", "completed" then results_diagnostic_path(@diagnostic)
    else root_path
    end
  end

  def questionnaire
    @current_bloc = current_bloc
    @questionnaire = @diagnostic.questionnaire || Questionnaire.find_by(active: true)
    @questions = @questionnaire.questions.active.by_bloc(@current_bloc)
    @total_blocs = @questionnaire.total_blocs
  end

  def submit_bloc
    bloc_number = params[:bloc].to_i

    @questionnaire = @diagnostic.questionnaire || Questionnaire.find_by(active: true)
    
    @questionnaire.questions.active.by_bloc(bloc_number).each do |question|
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

    if bloc_number >= @questionnaire.total_blocs
      Diagnostics::ScoringService.call(@diagnostic)
      redirect_to pay_diagnostic_path(@diagnostic)
    else
      redirect_to questionnaire_diagnostic_path(@diagnostic, bloc: bloc_number + 1)
    end
  end

  def results
    @trajectory = @diagnostic.primary_profile&.active_trajectory

    unless @diagnostic.pdf_generated?
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
    unless @diagnostic.paid? || @diagnostic.completed?
      redirect_to pay_diagnostic_path(@diagnostic)
    end
  end

  def payment_provider_param
    params[:payment_method].in?(%w[stripe pawapay]) ? params[:payment_method] : "stripe"
  end

  def handle_stripe_payment
    result = Payments::StripeCheckoutService.call(
      diagnostic:  @diagnostic,
      success_url: results_diagnostic_url(@diagnostic),
      cancel_url:  pay_diagnostic_url(@diagnostic)
    )

    if result[:success]
      redirect_to result[:url], allow_other_host: true
    else
      redirect_to pay_diagnostic_path(@diagnostic), alert: result[:error]
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
      redirect_to pay_diagnostic_path(@diagnostic), alert: result[:error]
    end
  end

  def detect_country
    request.headers["HTTP_X_RAILWAY_COUNTRY"] || cookies[:country].presence || "BJ"
  end

  def current_bloc
    (params[:bloc] || 1).to_i.clamp(1, 5)
  end
end
