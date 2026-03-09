class OnboardingController < ApplicationController
  before_action :authenticate_user!

  # Skip the ensure_onboarded! check so we don't end up in an infinite redirect loop
  skip_before_action :ensure_onboarded!, only: [ :show, :update ], raise: false

  def show
    # If the user is an admin or already onboarded, send them to the root path
    if current_user.onboarded?
      redirect_to root_path, notice: "Vous êtes déjà enregistré."
    end
  end

  def update
    if current_user.update(onboarding_params)
      # You can redirect to whatever path makes sense here, e.g. the diagnostics page
      redirect_to new_diagnostic_path, notice: "Profil complété avec succès !"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def onboarding_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :city,
      :country,
      :diploma,
      :employment_status
    )
  end
end
