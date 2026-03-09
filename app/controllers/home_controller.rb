class HomeController < ApplicationController
  def index
    @fields = Field.where(status: :active).order(:name)
    @random_careers = Career.published.order(Arel.sql("RANDOM()")).limit(6)
  end

  def cle
    # Page CLE - Citoyens Libres et Épanouis
  end
end
