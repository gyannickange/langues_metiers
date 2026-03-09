class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :ensure_onboarded!, unless: :devise_controller?

  private

  def ensure_onboarded!
    if user_signed_in? && !current_user.onboarded?
      redirect_to onboarding_path, notice: "Veuillez finaliser votre profil avant de continuer."
    end
  end
end
