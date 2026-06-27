module Admin
  class AcademicFieldsController < BaseController
    before_action :set_academic_field, only: %i[ show edit update destroy ]

    def index
      @pagy, @academic_fields = pagy(AcademicField.order(:position))
    end

    def show
    end

    def new
      @academic_field = AcademicField.new
    end

    def edit
    end

    def create
      @academic_field = AcademicField.new(academic_field_params)

      if @academic_field.save
        redirect_to admin_academic_field_path(@academic_field), notice: "Academic field created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @academic_field.update(academic_field_params)
        redirect_to admin_academic_field_path(@academic_field), notice: "Academic field updated successfully.", status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @academic_field.destroy!
      redirect_to admin_academic_fields_path, notice: "Academic field deleted successfully.", status: :see_other
    end

    private

    def set_academic_field
      @academic_field = AcademicField.find(params[:id])
    end

    def academic_field_params
      params.require(:academic_field).permit(:slug, :name, :position)
    end
  end
end
