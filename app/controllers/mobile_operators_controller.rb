# app/controllers/mobile_operators_controller.rb
class MobileOperatorsController < ApplicationController
  def index
    @operators = MobileOperator.active.by_country(params[:country] || "CI")
    render partial: "mobile_operators/list", locals: { operators: @operators }
  end
end
