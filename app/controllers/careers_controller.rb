class CareersController < ApplicationController
  # skip_before_action :authenticate_user!, only: [ :index ]

  def index
    @careers = Career.all.order(:title)
  end
end
