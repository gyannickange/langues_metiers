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
    redirect_to interest_diagnostics_path
  end

  def interest_start
    assessment = Assessment.find_by(active: true) || Assessment.first
    unless assessment
      redirect_to root_path, alert: "Aucune évaluation disponible pour le moment."
      return
    end
    @questions = assessment.diagnostic_questions.interest.active.ordered
  end

  def create_from_interest
    assessment = Assessment.find_by(active: true) || Assessment.first
    unless assessment
      redirect_to root_path, alert: "Aucune évaluation disponible pour le moment."
      return
    end

    questions = assessment.diagnostic_questions.interest.active.ordered
    answers = valid_answers_for(questions) do |_question, value|
      numeric_value = Integer(value, exception: false)
      numeric_value if (1..5).include?(numeric_value)
    end
    return redirect_to interest_diagnostics_path, alert: "Veuillez répondre à toutes les questions." unless answers

    ActiveRecord::Base.transaction do
      @diagnostic = current_user.diagnostics.create!(status: :in_progress, assessment: assessment)
      answers.each do |question, value|
        @diagnostic.diagnostic_answers.create!(
          diagnostic_question: question,
          dimension_slug:      question.filiere_slug,
          answer_value:        value.to_s,
          points_awarded:      value
        )
      end
    end

    redirect_to disc_diagnostic_path(@diagnostic)
  end

  def show
    redirect_to current_step_path(@diagnostic)
  end

  def interest
    @questions = active_assessment.diagnostic_questions.interest.active.ordered
  end

  def disc
    @questions = active_assessment.diagnostic_questions.disc.active.ordered
  end

  def competences
    @questions = active_assessment.diagnostic_questions.competence.active.ordered
  end

  def validation
    top_ids = top_career_ids
    if top_ids.empty?
      redirect_to competences_diagnostic_path(@diagnostic), alert: "Veuillez compléter les étapes précédentes."
      return
    end

    @top_careers = Career.where(id: top_ids).index_by(&:id).values_at(*top_ids).compact
    if @top_careers.size < 2
      redirect_to competences_diagnostic_path(@diagnostic), alert: "Veuillez compléter les étapes précédentes."
      return
    end
  end

  def submit_interest
    questions = active_assessment.diagnostic_questions.interest.active.ordered
    answers = valid_answers_for(questions) do |_question, value|
      numeric_value = Integer(value, exception: false)
      numeric_value if (1..5).include?(numeric_value)
    end
    return redirect_incomplete_answers(:interest) unless answers

    ActiveRecord::Base.transaction do
      answers.each do |question, value|
        answer = @diagnostic.diagnostic_answers.find_or_initialize_by(diagnostic_question: question)
        answer.assign_attributes(
          dimension_slug: question.filiere_slug,
          answer_value:   value.to_s,
          points_awarded: value
        )
        answer.save!
      end
    end
    redirect_to disc_diagnostic_path(@diagnostic)
  end

  def submit_disc
    questions = active_assessment.diagnostic_questions.disc.active.ordered
    answers = valid_answers_for(questions) do |_question, value|
      numeric_value = Integer(value, exception: false)
      numeric_value if (1..5).include?(numeric_value)
    end
    return redirect_incomplete_answers(:disc) unless answers

    ActiveRecord::Base.transaction do
      answers.each do |question, value|
        answer = @diagnostic.diagnostic_answers.find_or_initialize_by(diagnostic_question: question)
        answer.assign_attributes(
          dimension_slug: question.disc_type,
          answer_value:   value.to_s,
          points_awarded: value
        )
        answer.save!
      end
    end
    redirect_to competences_diagnostic_path(@diagnostic)
  end

  def submit_competences
    questions = active_assessment.diagnostic_questions.competence.active.ordered
    answers = valid_answers_for(questions) do |_question, value|
      numeric_value = Integer(value, exception: false)
      numeric_value if (1..5).include?(numeric_value)
    end
    return redirect_incomplete_answers(:competences) unless answers

    ActiveRecord::Base.transaction do
      answers.each do |question, value|
        answer = @diagnostic.diagnostic_answers.find_or_initialize_by(diagnostic_question: question)
        answer.assign_attributes(
          dimension_slug: question.competence_slug,
          answer_value:   value.to_s,
          points_awarded: value
        )
        answer.save!
      end
    end
    Diagnostics::PreScoringService.call(@diagnostic)
    redirect_to validation_diagnostic_path(@diagnostic)
  end

  def submit_validation
    known_ids = top_career_ids.map(&:to_s)
    affirmation_counts = (params[:affirmations] || {}).to_unsafe_h.slice(*known_ids)
    Diagnostics::ScoringService.call(@diagnostic, affirmation_counts)
    redirect_to pay_diagnostic_path(@diagnostic)
  rescue Diagnostics::ScoringService::InsufficientCareersError
    redirect_to competences_diagnostic_path(@diagnostic), alert: "Impossible de finaliser le diagnostic. Veuillez vérifier vos réponses."
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
    @results = Diagnostics::ResultsPresenter.new(@diagnostic)

    # Always regenerate PDF to ensure it reflects current data
    Diagnostics::GeneratePdfService.call(@diagnostic)
    @diagnostic.reload
  rescue StandardError => error
    Rails.logger.error("Diagnostic PDF generation failed for #{@diagnostic.id}: #{error.class}: #{error.message}")
    Diagnostics::GeneratePdfJob.perform_later(@diagnostic.id)
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

  def valid_answers_for(questions)
    answers = questions.filter_map do |question|
      value = yield(question, params.dig(:answers, question.id.to_s))
      [ question, value ] unless value.nil?
    end

    answers.to_h if answers.any? && answers.size == questions.size
  end

  def redirect_incomplete_answers(step)
    redirect_to public_send(:"#{step}_diagnostic_path", @diagnostic), alert: "Veuillez répondre à toutes les questions."
  end

  def top_career_ids
    score_data = @diagnostic.score_data
    return [] unless score_data.is_a?(Hash) && score_data["top_career_ids"].is_a?(Array)

    score_data["top_career_ids"].filter_map do |entry|
      entry.is_a?(Hash) ? entry["id"] : entry
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
end
