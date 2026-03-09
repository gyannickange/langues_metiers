require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "otp_email" do
    user = User.new(otp_code: "123456", email: "alice@insertrice.com")
    mail = UserMailer.with(user: user).otp_email

    assert_equal "Ton code de connexion Insertrice", mail.subject
    assert_equal [ "alice@insertrice.com" ], mail.to
    assert_match "123456", mail.body.encoded
  end
end
