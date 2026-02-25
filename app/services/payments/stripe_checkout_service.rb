# app/services/payments/stripe_checkout_service.rb
module Payments
  class StripeCheckoutService
    def self.call(**args)
      new(**args).call
    end

    def initialize(diagnostic:, success_url:, cancel_url:)
      @diagnostic  = diagnostic
      @success_url = success_url
      @cancel_url  = cancel_url
    end

    def call
      session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: [{
          price_data: {
            currency:     Rails.application.credentials.dig(:stripe, :currency) || "xof",
            product_data: { name: "Diagnostic de Repositionnement Stratégique" },
            unit_amount:  Rails.application.credentials.dig(:stripe, :price_amount) || 300000
          },
          quantity: 1
        }],
        mode:                 "payment",
        client_reference_id: @diagnostic.id,
        customer_email:      @diagnostic.user.email,
        success_url:         @success_url,
        cancel_url:          @cancel_url
      )

      @diagnostic.create_payment!(
        user:                @diagnostic.user,
        provider:            :stripe,
        provider_payment_id: session.id,
        status:              :pending
      )

      { success: true, url: session.url }
    rescue Stripe::StripeError => e
      { success: false, error: e.message }
    end
  end
end
