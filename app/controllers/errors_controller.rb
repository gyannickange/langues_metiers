class ErrorsController < ActionController::Base
  layout "error"

  ICONS = {
    "400" => "shield-alert",
    "404" => "compass",
    "422" => "ban",
    "500" => "server-crash"
  }.freeze

  def show
    @status = params[:status].presence_in(ICONS.keys) || "404"
    @icon = ICONS.fetch(@status)
    @title = t("errors.http_status.#{@status}.title")
    @description = t("errors.http_status.#{@status}.description")

    render status: @status.to_i
  end
end
