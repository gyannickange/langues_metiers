# test/services/webhooks/pawapay_handler_service_test.rb
require "test_helper"

class Webhooks::PawapayHandlerServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "pawa_hook#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user, status: :pending_payment, payment_provider: :pawapay)
    @payment    = @diagnostic.create_payment!(user: @user, provider: :pawapay,
                                              provider_payment_id: "pawa-456", status: :pending)
  end

  test "confirms payment on COMPLETED" do
    result = Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "COMPLETED")
    assert result[:processed]
    assert @payment.reload.confirmed?
    assert @diagnostic.reload.paid?
  end

  test "marks payment as failed on FAILED" do
    Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "FAILED")
    assert @payment.reload.failed?
  end

  test "is idempotent" do
    @payment.update!(status: :confirmed)
    result = Webhooks::PawapayHandlerService.call("depositId" => "pawa-456", "status" => "COMPLETED")
    assert result[:skipped]
  end
end
