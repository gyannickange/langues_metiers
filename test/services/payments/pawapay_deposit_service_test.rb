# test/services/payments/pawapay_deposit_service_test.rb
require "test_helper"

class Payments::PawapayDepositServiceTest < ActiveSupport::TestCase
  def setup
    @user       = User.create!(email: "pawa#{SecureRandom.hex(4)}@test.com", password: "password123")
    @diagnostic = Diagnostic.create!(user: @user)
  end

  test "creates payment and returns deposit_id on success" do
    stub_request(:post, %r{api\.pawapay\.io/v1/deposits})
      .to_return(
        status: 201,
        headers: { "Content-Type" => "application/json" },
        body: { depositId: "pawa-abc-123", status: "ACCEPTED" }.to_json
      )

    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         "2250701234567",
      operator_code: "ORANGE_CI"
    )

    assert result[:success]
    assert_equal "pawa-abc-123", result[:deposit_id]

    payment = @diagnostic.reload.payment
    assert_equal "pawapay",       payment.provider
    assert_equal "pawa-abc-123",  payment.provider_payment_id
    assert payment.pending?
  end

  test "returns error when Pawapay rejects" do
    stub_request(:post, %r{api\.pawapay\.io/v1/deposits})
      .to_return(
        status: 400,
        headers: { "Content-Type" => "application/json" },
        body: { status: "REJECTED", rejectionReason: "INVALID_MSISDN" }.to_json
      )

    result = Payments::PawapayDepositService.call(
      diagnostic:    @diagnostic,
      phone:         "bad_number",
      operator_code: "ORANGE_CI"
    )

    assert_not result[:success]
    assert_includes result[:error], "INVALID_MSISDN"
  end
end
