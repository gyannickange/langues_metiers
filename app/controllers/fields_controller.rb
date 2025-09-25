class FieldsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @fields = Field.where(status: :active)

    if @query.present?
      @fields = @fields.where("name ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%")
    end

    @fields = @fields.order(:name)
  end

  def show
    @field = Field.friendly.find(params[:slug])
    @roadmaps = @field.roadmaps.joins(:roadmap_steps).distinct.order(:title)
  end
end
