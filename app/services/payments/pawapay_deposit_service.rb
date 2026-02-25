# app/services/payments/pawapay_deposit_service.rb
require "net/http"
require "json"

module Payments
  class PawapayDepositService
    AMOUNT   = "3000"
    CURRENCY = "XOF"

    def self.call(**args)
      new(**args).call
    end

    def initialize(diagnostic:, phone:, operator_code:)
      @diagnostic    = diagnostic
      @phone         = phone
      @operator_code = operator_code
      @deposit_id    = SecureRandom.uuid
    end

    def call
      response = post_deposit
      body     = JSON.parse(response.body)

      if response.code.to_i == 201 && body["status"] == "ACCEPTED"
        deposit_id = body["depositId"] || @deposit_id
        @diagnostic.create_payment!(
          user:                @diagnostic.user,
          provider:            :pawapay,
          provider_payment_id: deposit_id,
          status:              :pending
        )
        { success: true, deposit_id: deposit_id }
      else
        reason = body["rejectionReason"] || body["message"] || "Payment rejected"
        { success: false, error: reason }
      end
    rescue => e
      { success: false, error: e.message }
    end

    private

    def post_deposit
      uri  = URI("#{base_url}/v1/deposits")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{api_token}"
      req["Content-Type"]  = "application/json"
      req.body = {
        depositId:            @deposit_id,
        amount:               AMOUNT,
        currency:             CURRENCY,
        correspondent:        @operator_code,
        recipient:            { type: "MSISDN", address: { value: @phone } },
        customerTimestamp:    Time.current.iso8601,
        statementDescription: "Diagnostic Repositionnement Strategique"
      }.to_json

      http.request(req)
    end

    def api_token = Rails.application.credentials.dig(:pawapay, :api_token)
    def base_url  = Rails.application.credentials.dig(:pawapay, :base_url) || "https://api.pawapay.io"
  end
end
