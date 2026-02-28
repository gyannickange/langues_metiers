require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "otp_email" do
    mail = UserMailer.otp_email
    assert_equal "Otp email", mail.subject
    assert_equal [ "to@example.org" ], mail.to
    assert_equal [ "alice@insertrice.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
