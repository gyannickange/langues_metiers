module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[show update]

    def index
      @pagy, @users = pagy(User.order(created_at: :desc))
    end

    def show
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Rôle mis à jour."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_user
      @user = User.includes(:skills, :diagnostics, :payments).find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
