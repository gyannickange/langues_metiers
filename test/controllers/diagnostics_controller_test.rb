require "test_helper"

class DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user  = User.create!(email: "ctrl#{SecureRandom.hex(4)}@test.com", password: "password123",
                          first_name: "Test", last_name: "User", city: "Cotonou",
                          country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Diagnostic Test #{SecureRandom.hex(4)}", active: true)
  end

  test "GET new redirects unauthenticated users to sign-in" do
    get new_diagnostic_path
    assert_redirected_to new_user_session_path
  end

  test "GET new redirects to interest collection path for authenticated user" do
    sign_in @user
    assert_no_difference "Diagnostic.count" do
      get new_diagnostic_path
    end
    assert_redirected_to interest_diagnostics_path
  end

  test "GET interest renders Likert questions for in_progress diagnostic" do
    sign_in @user
    @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Les langues m'attirent.", academic_field_slug: "langues", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get interest_diagnostic_path(d)
    assert_response :success
    assert_select "fieldset", count: 1
    assert_select "legend", text: /Les langues m'attirent/
    assert_select "input[type='radio'][value='1']", count: 1
    assert_select "input[type='radio'][value='5']", count: 1
  end

  test "GET interest renders Likert scale labels" do
    sign_in @user
    @assessment.diagnostic_questions.create!(
      kind: :interest, text: "L'espace m'attire.", academic_field_slug: "geo", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get interest_diagnostic_path(d)
    assert_response :success
    assert_includes response.body, "Pas du tout moi"
    assert_includes response.body, "Tout à fait moi"
  end

  test "GET disc renders for diagnostic with interest answers" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )
    @assessment.diagnostic_questions.create!(
      kind: :disc, text: "Je prends des initiatives.", disc_type: "D", position: 2
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    d.diagnostic_answers.create!(
      diagnostic_question: q, dimension_slug: "langues", answer_value: "3", points_awarded: 3
    )
    get disc_diagnostic_path(d)
    assert_response :success
    assert_select "fieldset", count: 1
    assert_select "fieldset.diagnostic-motion-item"
    assert_select ".peer-focus-visible\\:ring-2", count: 5
  end

  test "GET validation renders a Likert question per affirmation for each retained career" do
    sign_in @user
    d, c1, c2 = diagnostic_with_retained_careers

    get validation_diagnostic_path(d)

    assert_response :success
    assert_select "fieldset", count: 2
    assert_select "input[type='submit'][value*='paiement']"
    assert_includes response.body, c1.title
    assert_includes response.body, c2.title
    assert_includes response.body, "Ça me ressemble."
  end

  test "GET results blocked for pending_payment diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment, assessment: @assessment)
    get results_diagnostic_path(d)
    assert_redirected_to pay_diagnostic_path(d)
  end

  test "GET pay shows the free testing offer without payment methods" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment, assessment: @assessment)

    get pay_diagnostic_path(d)

    assert_response :success
    assert_includes response.body, "2 000 F CFA"
    assert_includes response.body, "0 F CFA"
    assert_select "button", text: /Accéder gratuitement à mes résultats/
    assert_select "h2", text: /Payer par carte bancaire/, count: 0
    assert_select "h2", text: /Payer par Mobile Money/, count: 0
  end

  test "POST process_payment unlocks a free diagnostic without an external payment" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment, assessment: @assessment)

    assert_difference "Payment.count", 1 do
      post process_payment_diagnostic_path(d)
    end

    assert_redirected_to results_diagnostic_path(d)
    assert d.reload.paid?
    assert d.payment.confirmed?
  end

  test "GET results renders honest empty states for sparse diagnostic data" do
    sign_in @user
    career = Career.create!(title: "Analyste", status: :published)
    d = Diagnostic.create!(
      user: @user,
      status: :completed,
      assessment: @assessment,
      primary_career: career,
      score_data: nil
    )

    get results_diagnostic_path(d)

    assert_response :success
    assert_select "h2", text: /Analyste/
    assert_select "[data-controller='pdf-status']", count: 0
    assert_select "p", text: /Aucune compétence clé n'est encore renseignée/
    assert_select "p", text: /Aucun axe de développement n'est encore renseigné/
    assert_not_includes response.body, "Analyse Stratégique"
    assert_not_includes response.body, "Stratège de projet"
  end

  test "GET results explains the recommendation and labels recorded Likert answers" do
    sign_in @user
    question = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Les langues m'attirent.", academic_field_slug: "langues", position: 1
    )
    career = Career.create!(title: "Traducteur", status: :published, required_skills: [])
    d = Diagnostic.create!(
      user: @user,
      status: :completed,
      assessment: @assessment,
      primary_career: career,
      score_data: {
        "dominant_disc_types"      => [ "D" ],
        "dominant_academic_fields" => [ "langues", "geo" ],
        "retained_careers"         => [ { "career_id" => career.id, "final_score" => 80.0 } ]
      }
    )
    d.diagnostic_answers.create!(diagnostic_question: question, dimension_slug: "langues", answer_value: "4", points_awarded: 4, effective_value: 4)

    Diagnostics::GeneratePdfService.stub(:call, ->(_diagnostic) {}) do
      get results_diagnostic_path(d)
    end

    assert_response :success
    assert_includes response.body, "Pourquoi ce métier vous correspond"
    assert_includes response.body, "Comment lire votre résultat"
    assert_includes response.body, "Plutôt moi"
    assert_select "p", text: /Les langues m'attirent\./
    assert_includes response.body, "Votre intérêt pour Langues et Géographie"
  end

  test "GET pdf status reports whether the report is ready" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :completed, assessment: @assessment)

    get pdf_status_diagnostic_path(d, format: :json)

    assert_response :success
    assert_equal({ "ready" => false }, response.parsed_body)
  end

  test "GET results remains available and queues a retry when PDF generation fails" do
    sign_in @user
    career = Career.create!(title: "Analyste", status: :published)
    d = Diagnostic.create!(user: @user, status: :completed, assessment: @assessment, primary_career: career)

    Diagnostics::GeneratePdfService.stub(:call, ->(_diagnostic) { raise Prawn::Errors::CannotFit }) do
      assert_enqueued_with(job: Diagnostics::GeneratePdfJob, args: [ d.id ]) do
        get results_diagnostic_path(d)
      end
    end

    assert_response :success
    assert_select "[data-controller='pdf-status']", count: 1
    assert_select ".diagnostic-status-pulse", count: 1
  end

  test "GET show redirects in_progress to interest when no answers" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get diagnostic_path(d)
    assert_redirected_to interest_diagnostic_path(d)
  end

  test "GET show resumes at validation once skills have been selected, instead of sending the user back to skills" do
    sign_in @user
    d, _c1, _c2 = diagnostic_with_retained_careers
    d.update!(selected_skills: [ "numerique" ])

    get diagnostic_path(d)

    assert_redirected_to validation_diagnostic_path(d)
  end

  test "GET show resumes at validation when a career-affirmation answer already exists" do
    sign_in @user
    d, c1, _c2 = diagnostic_with_retained_careers
    d.diagnostic_answers.create!(career: c1, affirmation_index: 0, affirmation_text: "Ça me ressemble.",
                                  answer_value: "5", points_awarded: 5, effective_value: 5)

    get diagnostic_path(d)

    assert_redirected_to validation_diagnostic_path(d)
  end

  test "GET show resumes at skills once disc is answered but no skills are selected yet" do
    sign_in @user
    d, _c1, _c2 = diagnostic_with_retained_careers

    get diagnostic_path(d)

    assert_redirected_to skills_diagnostic_path(d)
  end

  test "POST submit_interest rejects missing answers" do
    sign_in @user
    @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

    assert_no_difference "DiagnosticAnswer.count" do
      post submit_interest_diagnostic_path(d), params: { answers: {} }
    end

    assert_redirected_to interest_diagnostic_path(d)
  end

  test "POST submit_interest saves answer with academic_field_slug from question and Likert value" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "lettres", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

    assert_difference "DiagnosticAnswer.count", 1 do
      post submit_interest_diagnostic_path(d), params: { answers: { q.id => "4" } }
    end

    answer = d.diagnostic_answers.last
    assert_equal "lettres", answer.dimension_slug
    assert_equal "4",       answer.answer_value
    assert_equal 4,         answer.points_awarded
    assert_redirected_to disc_diagnostic_path(d)
  end

  test "POST submit_interest rejects out-of-range Likert value" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

    assert_no_difference "DiagnosticAnswer.count" do
      post submit_interest_diagnostic_path(d), params: { answers: { q.id => "6" } }
    end

    assert_redirected_to interest_diagnostic_path(d)
  end

  test "POST create_from_interest creates diagnostic and saves answers with academic_field_slug" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "geo", position: 1
    )

    assert_difference [ "Diagnostic.count", "DiagnosticAnswer.count" ], 1 do
      post submit_interest_diagnostics_path, params: { answers: { q.id => "3" } }
    end

    answer = DiagnosticAnswer.last
    assert_equal "geo", answer.dimension_slug
    assert_equal "3",   answer.answer_value
    assert_equal 3,     answer.points_awarded
    assert_redirected_to disc_diagnostic_path(Diagnostic.last)
  end

  test "POST create_from_interest rejects out-of-range Likert value" do
    sign_in @user
    @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )

    assert_no_difference [ "Diagnostic.count", "DiagnosticAnswer.count" ] do
      post submit_interest_diagnostics_path, params: { answers: { DiagnosticQuestion.last.id => "7" } }
    end

    assert_redirected_to interest_diagnostics_path
  end

  test "POST submit_disc rejects invalid answers" do
    sign_in @user
    question = @assessment.diagnostic_questions.create!(kind: :disc, text: "Q?", disc_type: "D", position: 1)
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

    assert_no_difference "DiagnosticAnswer.count" do
      post submit_disc_diagnostic_path(d), params: { answers: { question.id => "6" } }
    end

    assert_redirected_to disc_diagnostic_path(d)
  end

  test "POST submit_interest persists effective_value alongside points_awarded" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)

    post submit_interest_diagnostic_path(d), params: { answers: { q.id => "4" } }

    assert_equal 4, d.diagnostic_answers.last.effective_value
  end

  test "POST submit_disc persists an inverted effective_value for a reverse_scored question" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(
      kind: :interest, text: "Q?", academic_field_slug: "langues", position: 1
    )
    reversed = @assessment.diagnostic_questions.create!(
      kind: :disc, text: "Je déteste décider vite.", disc_type: "D", position: 2, reverse_scored: true
    )
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    d.diagnostic_answers.create!(diagnostic_question: q, dimension_slug: "langues", answer_value: "3", points_awarded: 3, effective_value: 3)
    Career.create!(title: "Filler #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [ "D" ])
    Career.create!(title: "Filler2 #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [ "D" ])

    post submit_disc_diagnostic_path(d), params: { answers: { reversed.id => "4" } }

    answer = d.diagnostic_answers.find_by(diagnostic_question: reversed)
    assert_equal 4, answer.points_awarded
    assert_equal 2, answer.effective_value
  end

  def diagnostic_with_retained_careers
    AcademicField.find_or_create_by!(slug: "langues") { |f| f.name = "Langues"; f.position = 1 }
    c1 = Career.create!(title: "Métier A #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [ "D" ], required_skills: [ "langues_etrangeres" ], affirmations: [ "Ça me ressemble." ])
    c2 = Career.create!(title: "Métier B #{SecureRandom.hex(4)}", status: :published, academic_field_slug: "langues", disc_types: [ "D" ], required_skills: [ "numerique" ], affirmations: [ "Ça aussi." ])
    d = Diagnostic.create!(
      user: @user, status: :in_progress, assessment: @assessment,
      score_data: {
        "dominant_academic_fields" => [ "langues" ],
        "dominant_disc_types"      => [ "D" ],
        "retained_careers" => [
          { "career_id" => c1.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false },
          { "career_id" => c2.id, "academic_field_slug" => "langues", "academic_field_score" => 90.0, "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false }
        ]
      }
    )
    [ d, c1, c2 ]
  end

  test "GET skills lists only the union of required_skills from the 2 retained careers" do
    sign_in @user
    d, _c1, _c2 = diagnostic_with_retained_careers

    get skills_diagnostic_path(d)

    assert_response :success
    assert_select "input[type='checkbox'][value='langues_etrangeres']", count: 1
    assert_select "input[type='checkbox'][value='numerique']", count: 1
    assert_select "input[type='checkbox']", count: 2
  end

  test "GET skills redirects to disc when the pool hasn't been computed yet" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment, score_data: {})

    get skills_diagnostic_path(d)

    assert_redirected_to disc_diagnostic_path(d)
  end

  test "POST submit_skills persists sanitized selected_skills restricted to the allowed union" do
    sign_in @user
    d, _c1, _c2 = diagnostic_with_retained_careers

    post submit_skills_diagnostic_path(d), params: { selected_skills: [ "numerique", "numerique", "", "bogus_slug" ] }

    assert_equal [ "numerique" ], d.reload.selected_skills
    assert_redirected_to validation_diagnostic_path(d)
  end

  test "POST submit_skills is idempotent across resubmissions" do
    sign_in @user
    d, _c1, _c2 = diagnostic_with_retained_careers

    post submit_skills_diagnostic_path(d), params: { selected_skills: [ "numerique" ] }
    post submit_skills_diagnostic_path(d), params: { selected_skills: [ "langues_etrangeres" ] }

    assert_equal [ "langues_etrangeres" ], d.reload.selected_skills
  end

  test "GET validation redirects when score data is malformed" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment, score_data: nil)

    get validation_diagnostic_path(d)

    assert_redirected_to skills_diagnostic_path(d)
  end

  test "POST submit_validation persists one DiagnosticAnswer per affirmation with a career snapshot" do
    sign_in @user
    d, c1, c2 = diagnostic_with_retained_careers

    assert_difference "DiagnosticAnswer.count", 2 do
      post submit_validation_diagnostic_path(d), params: {
        affirmations: { c1.id => { "0" => "5" }, c2.id => { "0" => "3" } }
      }
    end

    answer = d.diagnostic_answers.find_by(career: c1, affirmation_index: 0)
    assert_equal "Ça me ressemble.", answer.affirmation_text
    assert_equal "5", answer.answer_value
    assert_equal 5, answer.points_awarded
    assert_equal 5, answer.effective_value
  end

  test "POST submit_validation rejects incomplete affirmation ratings" do
    sign_in @user
    d, c1, _c2 = diagnostic_with_retained_careers

    assert_no_difference "DiagnosticAnswer.count" do
      post submit_validation_diagnostic_path(d), params: { affirmations: { c1.id => { "0" => "5" } } }
    end

    assert_redirected_to validation_diagnostic_path(d)
  end

  test "POST submit_validation rolls back already-saved answers when a later rating is out of range" do
    sign_in @user
    d, c1, c2 = diagnostic_with_retained_careers

    assert_no_difference "DiagnosticAnswer.count" do
      post submit_validation_diagnostic_path(d), params: {
        affirmations: { c1.id => { "0" => "5" }, c2.id => { "0" => "9" } }
      }
    end

    assert_redirected_to validation_diagnostic_path(d)
    assert_nil d.diagnostic_answers.find_by(career: c1, affirmation_index: 0),
      "the c1 answer must not survive when a later career's rating is invalid"
  end

  test "POST submit_validation is idempotent across resubmissions" do
    sign_in @user
    d, c1, c2 = diagnostic_with_retained_careers
    params = { affirmations: { c1.id => { "0" => "5" }, c2.id => { "0" => "3" } } }

    post submit_validation_diagnostic_path(d), params: params
    assert_no_difference "DiagnosticAnswer.count" do
      post submit_validation_diagnostic_path(d), params: { affirmations: { c1.id => { "0" => "2" }, c2.id => { "0" => "4" } } }
    end

    assert_equal 2, d.diagnostic_answers.find_by(career: c1, affirmation_index: 0).points_awarded
    assert_equal 4, d.diagnostic_answers.find_by(career: c2, affirmation_index: 0).points_awarded
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end
