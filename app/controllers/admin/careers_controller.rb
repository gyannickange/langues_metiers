module Admin
  class CareersController < BaseController
    before_action :set_career, only: [ :edit, :update, :destroy ]

    def index
      @query = params[:q].to_s.strip
      @status = params[:status]

      @careers = Career.order(created_at: :desc)
      
      if @query.present?
        search_query = "%#{@query}%"
        @careers = @careers.where("title ILIKE :q OR description ILIKE :q OR slug ILIKE :q", q: search_query)
      end

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
      params.require(:career).permit(:title, :slug, :description, :status, :kind, :first_action, :premium_pitch, key_skills: [])
    end
  end
end
