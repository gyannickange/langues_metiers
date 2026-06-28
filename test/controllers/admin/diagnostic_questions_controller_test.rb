require "test_helper"

class Admin::DiagnosticQuestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    @assessment = Assessment.create!(title: "Admin Diagnostic Questions #{SecureRandom.hex(4)}", active: false)
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "index shows an empty state when a filter matches no questions" do
    get admin_assessment_diagnostic_questions_path(@assessment, kind: "skill")

    assert_select "h3", text: "Aucune question"
  end

  test "index does not show the empty state when questions exist for the filter" do
    @assessment.diagnostic_questions.create!(kind: "skill", text: "Une question", position: 1, active: true, skill_slug: "numerique")

    get admin_assessment_diagnostic_questions_path(@assessment, kind: "skill")

    assert_select "h3", text: "Aucune question", count: 0
  end

  test "index highlights the active filter tab using the diagnostics-page pill style" do
    get admin_assessment_diagnostic_questions_path(@assessment, kind: "disc")

    disc_tab = css_select("a").find { |node| node.text.strip == "DISC" }
    assert_includes disc_tab["class"], "bg-white"

    interest_tab = css_select("a").find { |node| node.text.strip == "Intérêt" }
    assert_includes interest_tab["class"], "text-slate-400"
  end

  test "index groups questions by kind then position when viewing all kinds" do
    skill_q   = @assessment.diagnostic_questions.create!(kind: "skill", text: "Q-skill", position: 1, active: true, skill_slug: "numerique")
    disc_q    = @assessment.diagnostic_questions.create!(kind: "disc", text: "Q-disc", position: 1, active: true, disc_type: "D")
    interest_q = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q-interest", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    body = response.body
    assert_operator body.index(interest_q.text), :<, body.index(disc_q.text)
    assert_operator body.index(disc_q.text), :<, body.index(skill_q.text)
  end

  test "create auto-assigns the next position for the kind, ignoring any client-supplied value" do
    @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")

    post admin_assessment_diagnostic_questions_path(@assessment), params: {
      diagnostic_question: { kind: "interest", text: "Q2", active: true, academic_field_slug: "geo", position: 999 }
    }

    assert_redirected_to admin_assessment_diagnostic_questions_path(@assessment)
    assert_equal 2, DiagnosticQuestion.order(:created_at).last.position
  end

  test "update ignores a client-supplied position value" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 3, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { position: 999 } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal 3, question.reload.position
  end

  test "create persists academic_field_slug on an interest question" do
    assert_difference "DiagnosticQuestion.count", 1 do
      post admin_assessment_diagnostic_questions_path(@assessment), params: {
        diagnostic_question: {
          kind: "interest", text: "J'aime les langues", active: true,
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
        diagnostic_question: { kind: "interest", text: "Sans filière", active: true }
      }
    end
    assert_response :unprocessable_content
  end

  test "skill question persists its label into options" do
    post admin_assessment_diagnostic_questions_path(@assessment), params: {
      diagnostic_question: {
        kind: "skill", text: "Je maîtrise X", active: true,
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

  test "index renders a Modifier toggle and a Supprimer form for each question" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "button[data-action=?]", "click->row-toggle#openEdit"
    assert_select "form[action=?]", admin_assessment_diagnostic_question_path(@assessment, question)
  end

  test "each question's edit-form row is hidden by default" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(question)}_edit[hidden]"
  end

  test "update via inline full-row edit with a kind change replaces the whole table body" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { kind: "disc", text: "Une question", active: true, disc_type: "D" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=replace][target=?]", "questions_tbody"
    assert_equal "disc", question.reload.kind
  end

  test "update via inline full-row edit with invalid data re-renders just the edit-form row" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { kind: "interest", text: "", active: true, academic_field_slug: "langues" } },
          headers: { "X-Inline-Edit" => "true" }

    assert_response :unprocessable_content
    assert_select "turbo-stream[action=replace][target=?]", "#{dom_id(question)}_edit"
    assert_equal "Une question", question.reload.text
  end

  test "update via inline full-row edit ignores any client-supplied position" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 2, active: true, academic_field_slug: "langues")

    patch admin_assessment_diagnostic_question_path(@assessment, question),
          params: { diagnostic_question: { kind: "interest", text: "Une question", active: true, academic_field_slug: "langues", position: 999 } },
          headers: { "X-Inline-Edit" => "true" }

    assert_equal 2, question.reload.position
  end

  test "the new-question row is hidden by default and the trigger button can open it" do
    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr[hidden][data-row-toggle-target=?]", "newRow"
    assert_select "button[data-action=?]", "click->row-toggle#openNew"
  end

  test "the new-question row defaults its kind to the active filter tab" do
    get admin_assessment_diagnostic_questions_path(@assessment, kind: "disc")

    assert_select "tr[data-row-toggle-target=?] select[name=?] option[selected][value=?]",
                  "newRow", "diagnostic_question[kind]", "disc"
  end

  test "the new-question row defaults its kind to interest when viewing all kinds" do
    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr[data-row-toggle-target=?] select[name=?] option[selected][value=?]",
                  "newRow", "diagnostic_question[kind]", "interest"
  end

  test "create via inline row replaces the whole table body" do
    assert_difference "DiagnosticQuestion.count", 1 do
      post admin_assessment_diagnostic_questions_path(@assessment),
           params: { diagnostic_question: { kind: "interest", text: "Nouvelle question", active: true, academic_field_slug: "langues" } },
           headers: { "X-Inline-Edit" => "true" }
    end

    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action=replace][target=?]", "questions_tbody"
    assert_match "Nouvelle question", response.body
    assert_equal 1, DiagnosticQuestion.order(:created_at).last.position
  end

  test "create via inline row with invalid data re-renders just the new row with errors" do
    assert_no_difference "DiagnosticQuestion.count" do
      post admin_assessment_diagnostic_questions_path(@assessment),
           params: { diagnostic_question: { kind: "interest", text: "Sans filière", active: true } },
           headers: { "X-Inline-Edit" => "true" }
    end

    assert_response :unprocessable_content
    assert_select "turbo-stream[action=replace][target=?]", "new_diagnostic_question"
    assert_match "ne peut pas être vide", response.body
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

  test "reorder succeeds when ordered_ids only include the actual question rows (the JS contract the sortable controller must honor)" do
    q1 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q1", position: 1, active: true, academic_field_slug: "langues")
    q2 = @assessment.diagnostic_questions.create!(kind: "interest", text: "Q2", position: 2, active: true, academic_field_slug: "geo")

    get admin_assessment_diagnostic_questions_path(@assessment, kind: "interest")
    doc = Nokogiri::HTML5(response.body)
    tbody_children = doc.at_css("#questions_tbody").element_children
    # The tbody now also contains each question's hidden edit-form row and the hidden
    # new-question row as siblings — none of those carry data-id. Confirm that's really
    # the case (otherwise this test would pass for the wrong reason).
    assert_equal 5, tbody_children.size, "expected 2 questions + 2 paired edit rows + 1 new-row"
    ordered_ids = tbody_children.filter_map { |el| el["data-id"] }
    assert_equal [ q1.id, q2.id ], ordered_ids

    patch reorder_admin_assessment_diagnostic_questions_path(@assessment, kind: "interest"),
          params: { ordered_ids: ordered_ids.reverse }

    assert_response :no_content
    assert_equal 1, q2.reload.position
    assert_equal 2, q1.reload.position
  end

  test "the Modifier button and its paired edit-form row carry id-based params, not sibling-based pairing" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "button[data-action=?][data-row-toggle-display-id-param=?][data-row-toggle-edit-id-param=?]",
                  "click->row-toggle#openEdit", dom_id(question), "#{dom_id(question)}_edit"
    assert_select "tr##{dom_id(question)}_edit button[data-action=?][data-row-toggle-display-id-param=?][data-row-toggle-edit-id-param=?]",
                  "click->row-toggle#cancelEdit", dom_id(question), "#{dom_id(question)}_edit"
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

  test "index shows position as plain, non-editable text" do
    question = @assessment.diagnostic_questions.create!(kind: "interest", text: "Une question", position: 1, active: true, academic_field_slug: "langues")

    get admin_assessment_diagnostic_questions_path(@assessment)

    assert_select "tr##{dom_id(question)} td[data-inline-edit-param-value=?]", "position", count: 0
    assert_select "tr##{dom_id(question)}", text: /1/
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
