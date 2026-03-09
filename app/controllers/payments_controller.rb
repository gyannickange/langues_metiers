# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  before_action :authenticate_user!

  def status
    @payment = current_user.payments.find(params[:id])

    respond_to do |format|
      format.html
      format.turbo_stream do
        if @payment.confirmed?
          render turbo_stream: turbo_stream.replace(
            "payment-status",
            partial: "payments/confirmed",
            locals:  { diagnostic: @payment.diagnostic }
          )
        else
          render turbo_stream: turbo_stream.replace("payment-status", partial: "payments/waiting",
                                                    locals: { payment: @payment })
        end
      end
      format.json { render json: { status: @payment.status } }
    end
  end
end
