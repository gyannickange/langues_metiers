require "test_helper"

class DiagnosticTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "diag#{SecureRandom.hex(4)}@test.com", password: "password123")
  end

  test "valid with a user" do
    assert Diagnostic.new(user: @user).valid?
  end

  test "starts as pending_payment" do
    d = Diagnostic.create!(user: @user)
    assert d.pending_payment?
  end

  test "status lifecycle" do
    d = Diagnostic.create!(user: @user)
    d.paid!;        assert d.paid?
    d.in_progress!; assert d.in_progress?
    d.completed!;   assert d.completed?
  end

  test "score_data defaults to empty hash" do
    d = Diagnostic.create!(user: @user)
    assert_equal({}, d.score_data)
  end

  test "has_many diagnostic_answers" do
    assert_respond_to Diagnostic.new, :diagnostic_answers
  end

  test "belongs_to primary_profile optionally" do
    d = Diagnostic.new(user: @user)
    assert d.valid?   # primary_profile is optional
  end
end
