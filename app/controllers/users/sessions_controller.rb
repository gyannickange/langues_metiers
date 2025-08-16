# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout 'application'

  def create
    super do |user|
      flash[:notice] = t('devise.sessions.signed_in')
    end
  end

  def destroy
    super do
      flash[:notice] = t('devise.sessions.signed_out')
    end
  end

  protected

  def after_sign_in_path_for(resource)
    admin_root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end
