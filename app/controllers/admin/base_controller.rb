module Admin
  class BaseController < ApplicationController
    layout "admin"

    include Pagy::Backend
    include Pundit::Authorization

    ADMIN_SESSION_TIMEOUT = 30.days

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :enforce_admin_session_timeout
    before_action { PaperTrail.request.whodunnit = current_user&.id }

    private

    def require_admin!
      redirect_to root_path, alert: I18n.t("unauthorized", default: "Unauthorized") unless current_user&.admin?
    end

    def enforce_admin_session_timeout
      last_seen = session[:admin_last_seen_at]

      if last_seen && Time.zone.parse(last_seen) < ADMIN_SESSION_TIMEOUT.ago
        reset_session
        redirect_to new_user_session_path, alert: "Session expirée, merci de vous reconnecter."
        return
      end

      session[:admin_last_seen_at] = Time.zone.now.to_s
    end
  end
end
