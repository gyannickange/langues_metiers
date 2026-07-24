require "test_helper"

class Admin::DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    @user  = User.create!(email: "diag#{SecureRandom.hex(4)}@test.com", password: "password123",
                           first_name: "Diag", last_name: "Test", city: "Cotonou",
                           country: "BJ", diploma: "Licence", employment_status: "Étudiant")
    @assessment = Assessment.create!(title: "Admin Diagnostics Show #{SecureRandom.hex(4)}", active: false)

    @disc_question = @assessment.diagnostic_questions.create!(kind: :disc, text: "Je décide vite.", disc_type: "D", position: 1)

    @primary   = Career.create!(title: "Traducteur #{SecureRandom.hex(4)}",
                                 status: :published, academic_field_slug: "langues", disc_types: [ "D" ], required_skills: [], affirmations: %w[a b])
    @secondary = Career.create!(title: "Interprète #{SecureRandom.hex(4)}",
                                 status: :published, academic_field_slug: "geo", disc_types: [ "I" ], required_skills: [])

    @diagnostic = Diagnostic.create!(user: @user, assessment: @assessment, status: :completed,
                                      primary_career: @primary, complementary_career: @secondary)
    @disc_answer = @diagnostic.diagnostic_answers.create!(diagnostic_question: @disc_question, dimension_slug: "D", answer_value: "4", points_awarded: 4)

    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "show renders the plain answer list without scoring badges for a legacy diagnostic" do
    @diagnostic.update!(score_data: {
      "top_career_ids" => [ { "id" => @primary.id, "score" => 3 }, { "id" => @secondary.id, "score" => 0 } ]
    })

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select ".bg-indigo-50", count: 0
    assert_select "details", count: 0
    assert_select "h4", text: /#{Regexp.escape(@disc_question.text)}/
  end

  test "show renders the score overview cards and affirmation row for a fully scored diagnostic" do
    @diagnostic.diagnostic_answers.create!(career: @primary, affirmation_index: 0, affirmation_text: "a",
                                            answer_value: "5", points_awarded: 5, effective_value: 5)
    @diagnostic.update!(score_data: {
      "dominant_disc_types"      => [ "D" ],
      "dominant_academic_fields" => [ "langues" ],
      "retained_careers" => [
        {
          "career_id" => @primary.id, "academic_field_slug" => "langues", "academic_field_score" => 80.0,
          "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false,
          "skill_score" => 100.0, "missing_required_skills" => false, "affirmation_score" => 100.0, "final_score" => 100.0
        },
        {
          "career_id" => @secondary.id, "academic_field_slug" => "geo", "academic_field_score" => 50.0,
          "matched_disc_types" => [], "disc_match_count" => 0, "fallback" => true,
          "skill_score" => 0.0, "missing_required_skills" => true, "affirmation_score" => 0.0, "final_score" => 0.0
        }
      ]
    })

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select "details", count: 2
    assert_includes response.body, "Filtre de personnalité"
    assert_select "p", text: /Compétences \(40%\)/
    assert_includes response.body, "Métier 1 · « a (5/5) »"
    assert_select "[data-category='affirmation'][data-scored='true']"
  end

  test "show renders a confirmed payment" do
    Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe, status: :confirmed)

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select ".bg-emerald-50", text: "confirmed"
  end

  test "show renders the answer filter bar with category data attributes on each row" do
    @diagnostic.update!(score_data: {
      "dominant_disc_types"      => [ "D" ],
      "dominant_academic_fields" => [ "langues" ],
      "retained_careers" => [
        {
          "career_id" => @primary.id, "academic_field_slug" => "langues", "academic_field_score" => 80.0,
          "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false,
          "skill_score" => 100.0, "missing_required_skills" => false, "affirmation_score" => 100.0, "final_score" => 100.0
        },
        {
          "career_id" => @secondary.id, "academic_field_slug" => "geo", "academic_field_score" => 50.0,
          "matched_disc_types" => [], "disc_match_count" => 0, "fallback" => true,
          "skill_score" => 0.0, "missing_required_skills" => true, "affirmation_score" => 0.0, "final_score" => 0.0
        }
      ]
    })

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select "[data-controller='answer-filter']"
    assert_select "[data-answer-filter-filter-param='disc']"
    assert_select "[data-answer-filter-filter-param='scored']"
    assert_select "[data-answer-filter-filter-param='affirmation']"
    assert_select "button[aria-pressed='true'][data-answer-filter-filter-param='all']"
    assert_select "[data-answer-filter-target='empty']"
    assert_select "[data-category='disc'][data-scored='true']"
  end

  test "show exposes career filters and readable answer contributions" do
    @diagnostic.update!(score_data: {
      "dominant_disc_types"      => [ "D" ],
      "dominant_academic_fields" => [ "langues" ],
      "retained_careers" => [
        {
          "career_id" => @primary.id, "academic_field_slug" => "langues", "academic_field_score" => 80.0,
          "matched_disc_types" => [ "D" ], "disc_match_count" => 1, "fallback" => false,
          "skill_score" => 100.0, "missing_required_skills" => false, "affirmation_score" => 100.0, "final_score" => 100.0
        },
        {
          "career_id" => @secondary.id, "academic_field_slug" => "geo", "academic_field_score" => 50.0,
          "matched_disc_types" => [], "disc_match_count" => 0, "fallback" => true,
          "skill_score" => 0.0, "missing_required_skills" => true, "affirmation_score" => 0.0, "final_score" => 0.0
        }
      ]
    })

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select "[data-answer-filter-filter-param='career-#{@primary.id}']"
    assert_includes response.body, "Type DISC Dominant retenu"
    assert_includes response.body, "Filtre de personnalité"
    assert_includes response.body, "Choix de l’utilisateur"
  end

  test "show does not crash when the diagnostic has career-affirmation answers with no diagnostic_question" do
    career = Career.create!(title: "Analyste #{SecureRandom.hex(4)}", status: :published, affirmations: [ "Ça me ressemble." ])
    @diagnostic.diagnostic_answers.create!(career: career, affirmation_index: 0, affirmation_text: "Ça me ressemble.",
                                            answer_value: "5", points_awarded: 5, effective_value: 5)

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
  end
end
