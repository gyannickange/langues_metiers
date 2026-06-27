class HomeController < ApplicationController
  def index
    @random_careers = Career.diagnostic.published.order(Arel.sql("RANDOM()")).limit(6)
    @diagnostic_careers_count = Career.diagnostic.published.count
  end

  def cle
    # Page CLE - Citoyens Libres et Épanouis
  end
end
