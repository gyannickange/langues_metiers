# test/controllers/diagnostics_controller_test.rb
require "test_helper"

class DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "ctrl#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "GET new redirects unauthenticated users to login" do
    get new_diagnostic_path
    assert_redirected_to new_user_session_path
  end

  test "GET new renders for authenticated user" do
    sign_in @user
    get new_diagnostic_path
    assert_response :success
  end

  test "GET questionnaire blocks unpaid diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment)
    get questionnaire_diagnostic_path(d)
    assert_redirected_to new_diagnostic_path
  end

  test "GET questionnaire allows paid diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :paid)
    get questionnaire_diagnostic_path(d)
    assert_response :success
  end

  private

  def sign_in(user)
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end
end
