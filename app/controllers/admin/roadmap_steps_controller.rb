module Admin
  class RoadmapStepsController < BaseController
    before_action :set_roadmap, only: [ :index, :new, :create ]
    before_action :set_roadmap_step, only: [ :show, :edit, :update, :destroy ]
    before_action :set_field

    def index
      @pagy, @roadmap_steps = pagy(@roadmap.roadmap_steps.ordered)
    end

    def show
    end

    def new
      @roadmap_step = @roadmap.roadmap_steps.build
      @roadmap_step.order = (@roadmap.roadmap_steps.maximum(:order) || 0) + 1
    end

    def create
      @roadmap_step = @roadmap.roadmap_steps.build(roadmap_step_params)
      if @roadmap_step.save
        redirect_to admin_field_roadmap_roadmap_steps_path(@field, @roadmap), notice: "Étape créée avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @roadmap_step.update(roadmap_step_params)
        redirect_to admin_field_roadmap_roadmap_step_path(@field, @roadmap, @roadmap_step), notice: "Étape mise à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @roadmap_step.destroy
      redirect_to admin_field_roadmap_roadmap_steps_path(@field, @roadmap), notice: "Étape supprimée avec succès."
    end

    private

    def set_field
      @field = Field.friendly.find(params[:field_id])
    end

    def set_roadmap
      @roadmap = Roadmap.find(params[:roadmap_id])
    end

    def set_roadmap_step
      @roadmap_step = RoadmapStep.find(params[:id])
      @roadmap = @roadmap_step.roadmap
    end

    def roadmap_step_params
      params.require(:roadmap_step).permit(:title, :objective, :skills, :activities, :order)
    end
  end
end
