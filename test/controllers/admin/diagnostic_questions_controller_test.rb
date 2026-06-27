require "test_helper"

class Admin::DiagnosticQuestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    @assessment = Assessment.create!(title: "Admin Diagnostic Questions #{SecureRandom.hex(4)}", active: false)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "create persists academic_field_slug on an interest question" do
    assert_difference "DiagnosticQuestion.count", 1 do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: {
          kind: "interest", text: "J'aime les langues", position: 1, active: true,
          academic_field_slug: "langues"
        }
      }
    end

    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
    assert_equal "langues", DiagnosticQuestion.order(:created_at).last.academic_field_slug
  end

  test "interest question without academic_field_slug is rejected" do
    assert_no_difference "DiagnosticQuestion.count" do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: { kind: "interest", text: "Sans filière", position: 1, active: true }
      }
    end
    assert_response :unprocessable_content
  end

  test "skill question persists its label into options" do
    post admin_assessment_diagnostic_questions_path(@assessment), params: {
      diagnostic_question: {
        kind: "skill", text: "Je maîtrise X", position: 2, active: true,
        skill_slug: "numerique", skill_label: "Compétences numériques"
      }
    }

    question = DiagnosticQuestion.order(:created_at).last
    assert_equal "Compétences numériques", question.options.dig(0, "label")
  end

  test "destroy redirects with see_other so Turbo does not replay the DELETE" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    delete admin_assessment_diagnostic_question_path(@assessment, question)

    assert_response :see_other
    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
  end

  test "index has a link back to the assessment" do
    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "a[href=?]", edit_admin_assessment_path(@assessment)
  end

  test "index links edit and delete to the nested member routes" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "a[href=?]", edit_admin_assessment_diagnostic_question_path(@assessment, question)
    assert_select "form[action=?]", admin_assessment_diagnostic_question_path(@assessment, question)
  end

  test "new pre-fills the next position for the requested kind" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Q2", position: 2, active: true, academic_field_slug: "geo")

    get new_admin_assessment_diagnostic_question_path(@assessment, kind: "interest")

    assert_select "input#diagnostic_question_position[value=?]", "3"
  end

  test "new defaults position to 1 for a kind with no siblings, ignoring other kinds' positions" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Unrelated kind", position: 10, active: true, academic_field_slug: "langues")

    get new_admin_assessment_diagnostic_question_path(@assessment, kind: "skill")

    assert_select "input#diagnostic_question_position[value=?]", "1"
  end

  test "new question button on the index links with the active kind filter" do
    get admin_assessment_diagnostic_questions_path(@assessment, kind: "disc")

    assert_select "a[href=?]", new_admin_assessment_diagnostic_question_path(@assessment, kind: "disc")
  end

  test "reorder persists new positions for same-kind questions" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")
    q2 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q2", position: 2, active: true, academic_field_slug: "geo")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: "interest"),
          params: { ordered_ids: [ q2.id, q1.id ] }

    assert_response :no_content
    assert_equal 1, q2.reload.position
    assert_equal 2, q1.reload.position
  end

  test "reorder rejects ids that don't match the assessment's questions for that kind" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")
    other_assessment = Assessment.create!(title: "Other #{SecureRandom.hex(4)}", active: false)
    foreign = other_assessment.diagnostic_questions.create!(kind: "interest", text: "Foreign", position: 1, active: true, academic_field_slug: "langues")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: "interest"),
          params: { ordered_ids: [ q1.id, foreign.id ] }

    assert_response :unprocessable_content
    assert_equal 1, q1.reload.position
  end

  test "reorder requires a kind" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment), params: { ordered_ids: [ q1.id ] }

    assert_response :unprocessable_content
  end

  test "index does not render a drag handle when viewing all kinds" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "[data-sortable-handle]", count: 0
  end

  test "index renders a drag handle when filtered to a specific kind" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment, kind: "interest")

    assert_select "[data-sortable-handle]", count: 1
  end

  test "index renders each row with a stable turbo dom id" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(question)}"
  end

  test "update via turbo stream replaces the row with the new text" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Texte original", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "Texte corrigé" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=replace][target=?]", dom_id(question)
    assert_match "Texte corrigé", response.body
    assert_equal "Texte corrigé", question.reload.text
  end

  test "update via turbo stream replaces the row with the new position" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { position: 5 } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal 5, question.reload.position
  end

  test "update via turbo stream toggles active" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { active: "0" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal false, question.reload.active
  end

  test "update via turbo stream with blank text re-renders the row with an inline error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_response :unprocessable_content
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "Une question", question.reload.text
  end

  test "update via turbo stream carries the current kind filter to keep the drag handle column consistent" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "Texte corrigé" }, kind: "interest" },
          headers: { "X-Inline-Edit" => "true" }

    assert_select "[data-sortable-handle]", count: 1
  end

  test "index wires the question text cell to inline editing" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "td[data-controller=?][data-inline-edit-param-value=?] textarea[hidden]", "inline-edit", "text"
  end

  test "update via turbo stream with blank text keeps the text field visible with the error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { text: "" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_select "td[data-inline-edit-param-value=?] textarea:not([hidden])", "text"
    assert_select "td[data-inline-edit-param-value=?] span[hidden]", "text"
    assert_match "doit être rempli(e)", response.body
  end

  test "index wires the position cell to inline editing" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "td[data-controller=?][data-inline-edit-param-value=?] input[type=number][hidden]", "inline-edit", "position"
  end

  test "update via turbo stream with invalid position keeps the position field visible with the error" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { position: 0 } },
          headers: { "X-Inline-Edit" => "true" }

    assert_select "td[data-inline-edit-param-value=?] input:not([hidden])", "position"
    assert_match "doit être supérieur à 0", response.body
  end

  test "index shows an active checkbox reflecting each question's state" do
    active_q = @assessment.diagnostic_questions.create!(kind: "interest", text: "Active", position: 1, active: true, academic_field_slug: "langues")
    inactive_q = @assessment.diagnostic_questions.create!(kind: "interest", text: "Inactive", position: 2, active: false, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(active_q)} input[type=checkbox][checked]"
    assert_select "tr##{dom_id(inactive_q)} input[type=checkbox]:not([checked])"
  end

  test "update without the inline-edit header still redirects, even with Turbo's automatic turbo-stream Accept header" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    # This mimics exactly what Turbo Drive sends for ANY non-GET form submission by default
    # (see turbo.js's requestAcceptsTurboStreamResponse: `!request.isSafe || hasAttribute(...)`),
    # including the plain, unmodified <form> on the full edit page. No X-Inline-Edit header.
    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { kind: "interest", text: "Texte corrigé", position: 1, active: true, academic_field_slug: "langues" } },
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    assert_response :see_other
    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
  end
end
