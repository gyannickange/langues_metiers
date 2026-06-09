# app/controllers/diagnostics_controller.rb
class DiagnosticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diagnostic, only: [
    :show, :interest, :submit_interest, :disc, :submit_disc,
    :competences, :submit_competences, :validation, :submit_validation,
    :pay, :process_payment, :results, :pdf_status, :download_pdf
  ]
  before_action :require_paid!, only: [ :results, :pdf_status, :download_pdf ]

  def new
    assessment = Assessment.find_by(active: true) || Assessment.first
    unless assessment
      redirect_to root_path, alert: "Aucune évaluation disponible pour le moment."
      return
    end
    @diagnostic = current_user.diagnostics.create!(status: :in_progress, assessment: assessment)
    redirect_to interest_diagnostic_path(@diagnostic)
  end

  def show
    redirect_to current_step_path(@diagnostic)
  end

  def interest
    @questions = active_assessment.diagnostic_questions.interest.active.ordered
  end

  def disc
    @questions = active_assessment.diagnostic_questions.disc.active.ordered
    render plain: "disc step"
  end

  def competences
    @questions = active_assessment.diagnostic_questions.competence.active.ordered
    render plain: "competences step"
  end

  def validation
    render plain: "validation step"
  end

  def submit_interest
    active_assessment.diagnostic_questions.interest.active.ordered.each do |q|
      filiere_slug = params.dig(:answers, q.id.to_s)
      valid_slugs = q.options.map { |o| o["filiere_slug"] }
      next unless valid_slugs.include?(filiere_slug)
      answer = @diagnostic.diagnostic_answers.find_or_initialize_by(diagnostic_question: q)
      answer.assign_attributes(dimension_slug: filiere_slug, answer_value: filiere_slug, points_awarded: 1)
      answer.save!
    end
    redirect_to disc_diagnostic_path(@diagnostic)
  end

  def submit_disc
    head :ok
  end

  def submit_competences
    head :ok
  end

  def submit_validation
    head :ok
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

  def results
    @trajectory = @diagnostic.primary_career&.active_trajectory

    # Always regenerate PDF to ensure it reflects current data
    Diagnostics::GeneratePdfService.call(@diagnostic)
    @diagnostic.reload
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
    @diagnostic = if current_user.admin?
      Diagnostic.find(params[:id])
    else
      current_user.diagnostics.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path
  end

  def require_paid!
    unless @diagnostic.paid? || @diagnostic.completed?
      redirect_to pay_diagnostic_path(@diagnostic)
    end
  end

  def current_step_path(diagnostic)
    case diagnostic.status
    when "paid", "completed" then results_diagnostic_path(diagnostic)
    when "pending_payment"   then pay_diagnostic_path(diagnostic)
    when "in_progress"       then resolve_in_progress_step(diagnostic)
    else root_path
    end
  end

  def resolve_in_progress_step(diagnostic)
    answered_kinds = diagnostic.diagnostic_answers
      .joins(:diagnostic_question)
      .distinct
      .pluck("diagnostic_questions.kind")

    if answered_kinds.include?("competence")
      validation_diagnostic_path(diagnostic)
    elsif answered_kinds.include?("disc")
      competences_diagnostic_path(diagnostic)
    elsif answered_kinds.include?("interest")
      disc_diagnostic_path(diagnostic)
    else
      interest_diagnostic_path(diagnostic)
    end
  end

  def active_assessment
    @active_assessment ||= @diagnostic.assessment || Assessment.find_by(active: true)
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
end
