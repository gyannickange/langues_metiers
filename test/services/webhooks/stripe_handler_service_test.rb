# test/services/webhooks/stripe_handler_service_test.rb
require "test_helper"

class Webhooks::StripeHandlerServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "stripe_hook#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user, status: :pending_payment)
    @payment    = @diagnostic.create_payment!(user: @user, provider: :stripe,
                                              provider_payment_id: "cs_test_abc", status: :pending)
  end

  test "confirms payment and sets diagnostic to paid" do
    event = {
      "type" => "checkout.session.completed",
      "data" => { "object" => { "id" => "cs_test_abc", "payment_status" => "paid" } }
    }

    result = Webhooks::StripeHandlerService.call(event)

    assert result[:processed]
    assert @payment.reload.confirmed?
    assert @diagnostic.reload.paid?
    assert_not_nil @diagnostic.paid_at
  end

  test "is idempotent — skips already confirmed payment" do
    @payment.update!(status: :confirmed)
    result = Webhooks::StripeHandlerService.call(
      "type" => "checkout.session.completed",
      "data" => { "object" => { "id" => "cs_test_abc" } }
    )
    assert result[:skipped]
  end

  test "skips unknown event types" do
    result = Webhooks::StripeHandlerService.call("type" => "customer.created")
    assert result[:skipped]
  end
end
