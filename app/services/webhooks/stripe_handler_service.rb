# app/services/webhooks/stripe_handler_service.rb
module Webhooks
  class StripeHandlerService
    def self.call(event_data)
      new(event_data).call
    end

    def initialize(event_data)
      @event_data = event_data
    end

    def call
      case @event_data["type"]
      when "checkout.session.completed"
        handle_checkout_completed
      else
        { skipped: true }
      end
    end

    private

    def handle_checkout_completed
      session = @event_data.dig("data", "object")
      payment = Payment.find_by(provider_payment_id: session["id"], provider: :stripe)

      return { skipped: true } if payment.nil? || payment.confirmed?

      ActiveRecord::Base.transaction do
        payment.update!(status: :confirmed, webhook_confirmed_at: Time.current)
        payment.diagnostic.update!(status: :paid, paid_at: Time.current)
      end

      { processed: true }
    end
  end
end
