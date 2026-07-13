class LegalController < ApplicationController
  skip_before_action :ensure_onboarded!

  def terms; end

  def privacy; end
end
