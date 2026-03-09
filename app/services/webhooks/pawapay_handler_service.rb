# app/services/webhooks/pawapay_handler_service.rb
module Webhooks
  class PawapayHandlerService
    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
    end

    def call
      payment = Payment.find_by(provider_payment_id: @payload["depositId"], provider: :pawapay)
      return { skipped: true } if payment.nil? || payment.confirmed?

      case @payload["status"]
      when "COMPLETED"
        ActiveRecord::Base.transaction do
          payment.update!(status: :confirmed, webhook_confirmed_at: Time.current)
          payment.diagnostic.update!(status: :paid, paid_at: Time.current)
        end
        Diagnostics::GeneratePdfJob.perform_later(payment.diagnostic.id)
        { processed: true }
      when "FAILED"
        payment.update!(status: :failed)
        { processed: true }
      else
        { skipped: true }
      end
    end
  end
end
