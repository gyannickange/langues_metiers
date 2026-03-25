class CareersController < ApplicationController
  def index
    @careers = Career.published.order(:title)
  end
end
