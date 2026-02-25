# test/controllers/webhooks/stripe_controller_test.rb
require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  test "returns 200 for valid webhook" do
    payload = { type: "checkout.session.completed",
                data: { object: { id: "cs_x" } } }.to_json

    # Stub signature verification to always pass
    Stripe::Webhook.stub :construct_event, true do
      post "/webhooks/stripe",
        params: payload,
        headers: { "Stripe-Signature" => "t=123,v1=abc", "CONTENT_TYPE" => "application/json" }
    end

    assert_response :ok
  end

  test "returns 400 for bad signature" do
    Stripe::Webhook.stub :construct_event, ->(*) { raise Stripe::SignatureVerificationError.new("bad", "hdr") } do
      post "/webhooks/stripe",
        params: "{}",
        headers: { "Stripe-Signature" => "bad", "CONTENT_TYPE" => "application/json" }
    end

    assert_response :bad_request
  end
end
