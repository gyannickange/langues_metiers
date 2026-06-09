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

  test "GET new creates diagnostic and redirects to interest for authenticated user" do
    sign_in @user
    assert_difference "Diagnostic.count", 1 do
      get new_diagnostic_path
    end
    assert_redirected_to interest_diagnostic_path(Diagnostic.last)
  end

  test "GET interest renders for in_progress diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get interest_diagnostic_path(d)
    assert_response :success
  end

  test "GET disc renders for diagnostic with interest answers" do
    sign_in @user
    q = @assessment.diagnostic_questions.create!(kind: :interest, text: "Q?", options: [{ "label" => "X", "filiere_slug" => "langues" }], position: 1)
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    d.diagnostic_answers.create!(diagnostic_question: q, dimension_slug: "langues", answer_value: "langues", points_awarded: 1)
    get disc_diagnostic_path(d)
    assert_response :success
  end

  test "GET results blocked for pending_payment diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment, assessment: @assessment)
    get results_diagnostic_path(d)
    assert_redirected_to pay_diagnostic_path(d)
  end

  test "GET show redirects in_progress to interest when no answers" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :in_progress, assessment: @assessment)
    get diagnostic_path(d)
    assert_redirected_to interest_diagnostic_path(d)
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end
