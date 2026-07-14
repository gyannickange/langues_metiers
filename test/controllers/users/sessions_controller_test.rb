require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM_HEADERS = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  test "sign-in presents Google and OTP authentication" do
    get new_user_session_path

    assert_response :success
    assert_select "form[action='#{send_otp_path}']", count: 1
    assert_select "input[type='email'][autocomplete='email']", count: 1
    assert_select "form[action='#{user_google_oauth2_omniauth_authorize_path}']", count: 1
  end

  test "requesting a code returns the accessible OTP state" do
    email = "otp-polish@example.com"

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post send_otp_path, params: { email: email }, headers: TURBO_STREAM_HEADERS
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match(/target="auth_flow"/, response.body)
    assert_match(/autocomplete="one-time-code"/, response.body)
    assert_match(/data-controller="otp-resend"/, response.body)
    assert_match(/role="status"/, response.body)
    assert User.exists?(email: email)
  end

  test "an invalid code is announced and remains recoverable" do
    user = User.create!(email: "invalid-otp@example.com", password: "password123")
    user.generate_otp!

    post verify_otp_path,
         params: { email: user.email, otp_code: "000000" },
         headers: TURBO_STREAM_HEADERS

    assert_response :success
    assert_match(/role="alert"/, response.body)
    assert_match(/aria-live="assertive"/, response.body)
    assert_match(/data-controller="otp-resend"/, response.body)
  end
end
