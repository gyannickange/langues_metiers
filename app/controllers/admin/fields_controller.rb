module Admin
  class FieldsController < BaseController
    before_action :set_field, only: [ :edit, :update, :destroy ]

    def index
      @pagy, @fields = pagy(Field.order(created_at: :desc))
    end

    def new
      @field = Field.new
    end

    def create
      @field = Field.new(field_params)
      if @field.save
        redirect_to admin_fields_path, notice: I18n.t("Field created", default: "Field created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @field.update(field_params)
        redirect_to admin_fields_path, notice: I18n.t("Field updated", default: "Field updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @field.destroy
      redirect_to admin_fields_path, notice: I18n.t("Field deleted", default: "Field deleted")
    end

    private

    def set_field
      @field = Field.friendly.find(params[:id])
    end

    def field_params
      params.require(:field).permit(:name, :description, :status)
    end
  end
end
