require "test_helper"

class DiagnosticTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "diag#{SecureRandom.hex(4)}@test.com", password: "password123", first_name: "Test", last_name: "User", city: "Test City", country: "CI", diploma: "Master", employment_status: "En emploi")
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

  test "belongs_to primary_career optionally" do
    d = Diagnostic.new(user: @user)
    assert d.valid?   # primary_career is optional
  end

  test "is free during the testing phase while preserving the standard price" do
    assert_equal 0, Diagnostic.price
    assert_equal 2_000, Diagnostic.standard_price
    assert_equal "0 F CFA", Diagnostic.formatted_price
    assert_equal "2 000 F CFA", Diagnostic.formatted_standard_price
  end

  test "a reminder queue failure does not prevent an in-progress diagnostic from being created" do
    DiagnosticReminderJob.stub(:set, ->(**) { raise ActiveJob::EnqueueError, "queue unavailable" }) do
      diagnostic = assert_nothing_raised do
        Diagnostic.create!(user: @user, status: :in_progress)
      end

      assert diagnostic.persisted?
      assert diagnostic.in_progress?
    end
  end
end
