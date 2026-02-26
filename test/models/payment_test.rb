require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "pay#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
  end

  test "valid with required attributes" do
    assert Payment.new(user: @user, diagnostic: @diagnostic, provider: :stripe).valid?
  end

  test "starts as pending" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    assert p.pending?
  end

  test "can be confirmed" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    p.confirmed!
    assert p.confirmed?
  end

  test "defaults to 300000 centimes XOF" do
    p = Payment.create!(user: @user, diagnostic: @diagnostic, provider: :stripe)
    assert_equal 300000, p.amount_cents
    assert_equal "XOF",  p.currency
  end
end
