require "test_helper"

class Admin::DiagnosticQuestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    @assessment = Assessment.create!(title: "Admin Diagnostic Questions #{SecureRandom.hex(4)}", active: false)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "create persists filiere_slug on an interest question" do
    assert_difference "DiagnosticQuestion.count", 1 do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: {
          kind: "interest", text: "J'aime les langues", position: 1, active: true,
          filiere_slug: "langues"
        }
      }
    end

    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
    assert_equal "langues", DiagnosticQuestion.order(:created_at).last.filiere_slug
  end

  test "interest question without filiere_slug is rejected" do
    assert_no_difference "DiagnosticQuestion.count" do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: { kind: "interest", text: "Sans filière", position: 1, active: true }
      }
    end
    assert_response :unprocessable_content
  end

  test "competence question persists its label into options" do
    post admin_assessment_diagnostic_questions_path(@assessment), params: {
      diagnostic_question: {
        kind: "competence", text: "Je maîtrise X", position: 2, active: true,
        competence_slug: "numerique", competence_label: "Compétences numériques"
      }
    }

    question = DiagnosticQuestion.order(:created_at).last
    assert_equal "Compétences numériques", question.options.dig(0, "label")
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, filiere_slug: "langues")

    delete admin_assessment_diagnostic_question_path(@assessment, question)

    assert_response :see_other
    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
  end

  test "index has a link back to the assessment" do
    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "a[href=?]", edit_admin_assessment_path(@assessment)
  end

  test "index links edit and delete to the nested member routes" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, filiere_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "a[href=?]", edit_admin_assessment_diagnostic_question_path(@assessment, question)
    assert_select "form[action=?]", admin_assessment_diagnostic_question_path(@assessment, question)
  end

  test "new pre-fills the next position for the requested kind" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, filiere_slug: "langues")
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Q2", position: 2, active: true, filiere_slug: "geo")

    get new_admin_assessment_diagnostic_question_path(@assessment, kind: "interest")

    assert_select "input#diagnostic_question_position[value=?]", "3"
  end

  test "new defaults position to 1 for a kind with no siblings, ignoring other kinds' positions" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Unrelated kind", position: 10, active: true, filiere_slug: "langues")

    get new_admin_assessment_diagnostic_question_path(@assessment, kind: "competence")

    assert_select "input#diagnostic_question_position[value=?]", "1"
  end

  test "new question button on the index links with the active kind filter" do
    get admin_assessment_diagnostic_questions_path(@assessment, kind: "disc")

    assert_select "a[href=?]", new_admin_assessment_diagnostic_question_path(@assessment, kind: "disc")
  end

  test "reorder persists new positions for same-kind questions" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, filiere_slug: "langues")
    q2 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q2", position: 2, active: true, filiere_slug: "geo")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: "interest"),
          params: { ordered_ids: [ q2.id, q1.id ] }

    assert_response :no_content
    assert_equal 1, q2.reload.position
    assert_equal 2, q1.reload.position
  end

  test "reorder rejects ids that don't match the assessment's questions for that kind" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, filiere_slug: "langues")
    other_assessment = Assessment.create!(title: "Other #{SecureRandom.hex(4)}", active: false)
    foreign = other_assessment.diagnostic_questions.create!(kind: "interest", text: "Foreign", position: 1, active: true, filiere_slug: "langues")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: "interest"),
          params: { ordered_ids: [ q1.id, foreign.id ] }

    assert_response :unprocessable_content
    assert_equal 1, q1.reload.position
  end

  test "reorder requires a kind" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, filiere_slug: "langues")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment), params: { ordered_ids: [ q1.id ] }

    assert_response :unprocessable_content
  end

  test "index does not render a drag handle when viewing all kinds" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, filiere_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "[data-sortable-handle]", count: 0
  end

  test "index renders a drag handle when filtered to a specific kind" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, filiere_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment, kind: "interest")

    assert_select "[data-sortable-handle]", count: 1
  end
end
