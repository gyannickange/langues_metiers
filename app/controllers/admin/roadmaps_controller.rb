module Admin
  class RoadmapsController < BaseController
    before_action :set_field, only: [ :index, :new, :create ]
    before_action :set_roadmap, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @roadmaps = pagy(@field.roadmaps.order(:title))
    end

    def show
      @roadmap_steps = @roadmap.roadmap_steps.ordered
      @associated_fields = @roadmap.fields
    end

    def new
      @roadmap = Roadmap.new
      @fields = Field.where(status: :active).order(:name)
    end

    def create
      @roadmap = Roadmap.new(roadmap_params)
      if @roadmap.save
        # Associer la roadmap au field courant
        RoadmapField.create!(roadmap: @roadmap, field: @field)

        # Associer à d'autres fields si spécifiés
        if params[:roadmap][:field_ids].present?
          additional_field_ids = params[:roadmap][:field_ids].reject(&:blank?) - [ @field.id ]
          additional_field_ids.each do |field_id|
            field = Field.find(field_id)
            RoadmapField.find_or_create_by!(roadmap: @roadmap, field: field)
          end
        end

        redirect_to admin_field_roadmaps_path(@field), notice: "Roadmap créée avec succès."
      else
        @fields = Field.where(status: :active).order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @fields = Field.where(status: :active).order(:name)
      @selected_field_ids = @roadmap.fields.pluck(:id)
    end

    def update
      if @roadmap.update(roadmap_params)
        # Mettre à jour les associations avec les fields
        if params[:roadmap][:field_ids].present?
          new_field_ids = params[:roadmap][:field_ids].reject(&:blank?)
          current_field_ids = @roadmap.fields.pluck(:id).map(&:to_s)

          # Supprimer les associations qui ne sont plus sélectionnées
          to_remove = current_field_ids - new_field_ids
          to_remove.each do |field_id|
            @roadmap.roadmap_fields.joins(:field).where(fields: { id: field_id }).destroy_all
          end

          # Ajouter les nouvelles associations
          to_add = new_field_ids - current_field_ids
          to_add.each do |field_id|
            field = Field.find(field_id)
            RoadmapField.find_or_create_by!(roadmap: @roadmap, field: field)
          end
        end

        redirect_to admin_field_roadmap_path(@field, @roadmap), notice: "Roadmap mise à jour avec succès."
      else
        @fields = Field.where(status: :active).order(:name)
        @selected_field_ids = @roadmap.fields.pluck(:id)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @roadmap.destroy
      redirect_to admin_field_roadmaps_path(@field), notice: "Roadmap supprimée avec succès."
    end

    private

    def set_field
      @field = Field.friendly.find(params[:field_id])
    end

    def set_roadmap
      @roadmap = Roadmap.find(params[:id])
    end

    def roadmap_params
      params.require(:roadmap).permit(:title, :description)
    end
  end
end
