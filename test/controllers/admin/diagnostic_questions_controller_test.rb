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
end
