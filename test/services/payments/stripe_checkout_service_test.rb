# test/services/payments/stripe_checkout_service_test.rb
require "test_helper"

class Payments::StripeCheckoutServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "stripe#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
    @urls       = { success_url: "http://test.host/success", cancel_url: "http://test.host/cancel" }
  end

  test "creates payment and returns checkout URL" do
    fake_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub :create, fake_session do
      result = Payments::StripeCheckoutService.call(diagnostic: @diagnostic, **@urls)

      assert result[:success]
      assert_equal "https://checkout.stripe.com/pay/cs_test_123", result[:url]

      payment = @diagnostic.reload.payment
      assert_not_nil payment
      assert_equal "stripe",      payment.provider
      assert_equal "cs_test_123", payment.provider_payment_id
      assert payment.pending?
    end
  end

  test "returns error when Stripe raises" do
    Stripe::Checkout::Session.stub :create, ->(*) { raise Stripe::StripeError, "Card declined" } do
      result = Payments::StripeCheckoutService.call(diagnostic: @diagnostic, **@urls)
      assert_not result[:success]
      assert_includes result[:error], "Card declined"
    end
  end
end
