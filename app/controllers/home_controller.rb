class HomeController < ApplicationController
  def index
    @fields = Field.where(status: :active).order(:name)
  end

  def cle
    # Page CLE - Citoyens Libres et Épanouis
  end
end
