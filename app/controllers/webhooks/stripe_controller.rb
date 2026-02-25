# app/controllers/webhooks/stripe_controller.rb
module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_stripe_signature

    def receive
      event_data = JSON.parse(request.body.read)
      Webhooks::StripeHandlerService.call(event_data)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def verify_stripe_signature
      payload    = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      secret     = Rails.application.credentials.dig(:stripe, :webhook_secret)

      Stripe::Webhook.construct_event(payload, sig_header, secret)
      request.body.rewind
    rescue Stripe::SignatureVerificationError
      head :bad_request
    end
  end
end
