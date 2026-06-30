require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "otp_email" do
    user = User.new(otp_code: "123456", email: "alice@Insertrix.com")
    mail = UserMailer.with(user: user).otp_email

    assert_equal "Ton code de connexion Insertrix", mail.subject
    assert_equal [ "alice@Insertrix.com" ], mail.to
    assert_match "123456", mail.body.encoded
  end
end
