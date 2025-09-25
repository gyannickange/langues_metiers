module Admin
  class BaseController < ApplicationController
    layout "admin"

    include Pagy::Backend
    include Pundit::Authorization

    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      redirect_to root_path, alert: I18n.t("unauthorized", default: "Unauthorized") unless current_user&.admin?
    end
  end
end
