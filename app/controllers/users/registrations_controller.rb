# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout 'application'

  protected

  def after_sign_up_path_for(resource)
    profile_path
  end

  def after_update_path_for(resource)
    profile_path
  end
end
