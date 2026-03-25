# test/controllers/diagnostics_controller_test.rb
require "test_helper"

class DiagnosticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "ctrl#{SecureRandom.hex(4)}@test.com", password: "password123", first_name: "Test", last_name: "User", city: "Test City", country: "CI", diploma: "Master", employment_status: "En emploi")
  end

  test "GET new redirects to sign-in for unauthenticated users" do
    get new_diagnostic_path
    assert_redirected_to new_user_session_path
  end

  test "GET new renders coming_soon for regular authenticated users" do
    sign_in @user
    get new_diagnostic_path
    assert_response :success
    assert_select "h2", text: /Bientôt disponible/
  end

  test "GET new creates diagnostic and redirects for admin users" do
    admin = User.create!(email: "admin#{SecureRandom.hex(4)}@test.com", password: "password123", role: :admin)
    sign_in admin
    assert_difference "Diagnostic.count", 1 do
      get new_diagnostic_path
    end
    assert_redirected_to questionnaire_diagnostic_path(Diagnostic.last)
  end

  test "GET results blocks unpaid diagnostic" do
    sign_in @user
    d = Diagnostic.create!(user: @user, status: :pending_payment)
    get results_diagnostic_path(d)
    assert_redirected_to pay_diagnostic_path(d)
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
