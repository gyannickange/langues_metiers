require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "GET terms renders the public terms page" do
    get terms_path

    assert_response :success
    assert_select "h1", text: "Conditions générales"
    assert_select "a[href='#{privacy_path}']", minimum: 1
    assert_select "meta[name='description']"
  end

  test "GET privacy renders the public privacy page" do
    get privacy_path

    assert_response :success
    assert_select "h1", text: "Politique de confidentialité"
    assert_select "section#cookies"
    assert_select "a[href='#{terms_path}']", minimum: 1
  end

  test "legal pages remain accessible to a signed-in user who has not completed onboarding" do
    user = User.create!(email: "legal-reader@example.com", password: "password123")
    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    get privacy_path

    assert_response :success
  end
end
