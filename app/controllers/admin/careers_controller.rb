module Admin
  class CareersController < BaseController
    before_action :set_career, only: [ :show, :edit, :update, :destroy ]

    def index
      @query = params[:q].to_s.strip
      @status = params[:status]

      @careers = Career.order(created_at: :desc)
      @careers = @careers.where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?
      @careers = @careers.where(status: @status) if @status.present?
      @pagy, @careers = pagy(@careers)
    end

    def new
      @career = Career.new
    end

    def create
      @career = Career.new(career_params)
      if @career.save
        redirect_to admin_careers_path, notice: t("Career created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @career.update(career_params)
        redirect_to admin_careers_path, notice: t("Career updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @career.destroy
      redirect_to admin_careers_path, notice: t("Career deleted")
    end

    private

    def set_career
      @career = Career.find(params[:id])
    end

    def career_params
      params.require(:career).permit(:title, :description, :status)
    end
  end
end
