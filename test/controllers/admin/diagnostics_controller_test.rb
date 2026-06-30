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
    assert_select "p", text: /#{Regexp.escape(@disc_question.text)}/
  end

  test "show renders the recap line, per-answer badge, and affirmation row for a fully scored diagnostic" do
    @diagnostic.update!(score_data: {
      "dominant_disc_types"     => [ "D" ],
      "dominant_academic_field" => nil,
      "top_career_ids" => [
        {
          "id" => @primary.id, "score" => 3,
          "disc_match" => 3, "academic_field_match" => 0, "comp_match" => 0,
          "matched_disc_types" => [ "D" ], "matched_skills" => {}
        },
        {
          "id" => @secondary.id, "score" => 0,
          "disc_match" => 0, "academic_field_match" => 0, "comp_match" => 0,
          "matched_disc_types" => [], "matched_skills" => {}
        }
      ],
      "affirmation_breakdown" => {
        @primary.id.to_s => { "checked_affirmations" => [ "a" ], "bonus" => 1, "max_bonus" => 2 }
      }
    })

    get admin_diagnostic_path(@diagnostic)

    assert_response :success
    assert_select "div", text: /Métier 1 : 4 pts · Métier 2 : 0 pts/
    assert_select ".bg-indigo-50", text: /Métier 1 · \+3 pts/
    assert_select "p", text: /Affirmation validée pour Métier 1 : « a »/
  end
end
