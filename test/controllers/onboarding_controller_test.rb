require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "onboarding-#{SecureRandom.hex(8)}@example.com",
      password: "password123"
    )

    post user_session_path,
      params: { user: { email: @user.email, password: "password123" } },
      headers: @default_headers
  end

  test "shows the required onboarding form" do
    get onboarding_path, headers: @default_headers

    assert_response :success
    assert_select "h1", text: "Finalisez votre profil"
    assert_select "form[action='#{onboarding_path}']" do
      assert_select "input[required]", count: 4
      assert_select "select[required]", count: 2
      assert_select "button[type='submit']", text: /Enregistrer et continuer/
    end
  end

  test "shows an accessible error summary when the user update fails" do
    # Onboarding fields have no model validations; an invalid email exercises the
    # controller's existing failure render without changing production behavior.
    @user.update_column(:email, "")

    patch onboarding_path,
      params: {
        user: {
          first_name: "",
          last_name: "",
          city: "",
          country: "",
          diploma: "",
          employment_status: ""
        }
      },
      headers: @default_headers

    assert_response :unprocessable_entity
    assert_select "[role='alert'][aria-labelledby='onboarding-errors-heading']" do
      assert_select "#onboarding-errors-heading", count: 1
      assert_select "li", minimum: 1
    end
  end
end
