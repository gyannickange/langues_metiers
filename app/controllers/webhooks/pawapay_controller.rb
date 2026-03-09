# app/controllers/webhooks/pawapay_controller.rb
module Webhooks
  class PawapayController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload = JSON.parse(request.body.read)
      Webhooks::PawapayHandlerService.call(payload)
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
